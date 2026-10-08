// SPDX-License-Identifier: Apache-2.0
// 阅读路线：存储适配器 → 时间步准备 → 分块碰撞 → 固定顺序汇总 → 提交。
// prepare 只生成待写回结果，commit 才修改粒子，避免失败时只更新了一半。
#include "batch.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <limits>
#include <map>
#include <set>
#include <tuple>
#include <unordered_map>

#ifdef _OPENMP
#include <omp.h>
#endif

namespace algoplasma::mcc {
namespace {

using Clock = std::chrono::steady_clock;

[[nodiscard]] Real seconds_since(const Clock::time_point start) {
    return std::chrono::duration<Real>(Clock::now() - start).count();
}

void add_ledger(ConservationLedger& target, const ConservationLedger& source) {
    target.charge_before_c += source.charge_before_c;
    target.charge_after_c += source.charge_after_c;
    target.momentum_before_kg_m_per_s += source.momentum_before_kg_m_per_s;
    target.momentum_after_kg_m_per_s += source.momentum_after_kg_m_per_s;
    target.kinetic_before_j += source.kinetic_before_j;
    target.kinetic_after_j += source.kinetic_after_j;
    target.internal_before_j += source.internal_before_j;
    target.internal_after_j += source.internal_after_j;
    target.released_energy_j += source.released_energy_j;
    target.radiated_or_unresolved_j += source.radiated_or_unresolved_j;
    target.energy_residual_j += source.energy_residual_j;
    target.tolerance_j += source.tolerance_j;
}

void add_reservoir(ReservoirDelta& target, const ReservoirDelta& source) {
    target.species = source.species;
    target.state = source.state;
    target.physical_particles += source.physical_particles;
    target.momentum_kg_m_per_s += source.momentum_kg_m_per_s;
    target.kinetic_energy_j += source.kinetic_energy_j;
    target.internal_energy_j += source.internal_energy_j;
}

void require_finite(const Real value, const char* label) {
    if (!std::isfinite(value)) throw Error(std::string(label) + " overflowed during batch reduction");
}

bool same_background(const CellBackground& a, const CellBackground& b) noexcept {
    const auto& x = a.component;
    const auto& y = b.component;
    return a.cell == b.cell && x.species == y.species && x.state == y.state &&
        x.density_m3 == y.density_m3 && x.temperature_k == y.temperature_k &&
        x.drift_m_per_s.x == y.drift_m_per_s.x &&
        x.drift_m_per_s.y == y.drift_m_per_s.y &&
        x.drift_m_per_s.z == y.drift_m_per_s.z;
}

struct BlockResult {
    std::uint64_t visited{0};
    std::uint64_t candidates{0};
    std::uint64_t real_events{0};
    std::uint64_t null_events{0};
    std::vector<ParticleChange> changes;
    std::vector<CreatedProduct> created;
    std::vector<ParticleEvent> events;
    std::map<ReactionId, std::uint64_t> by_reaction;
    std::vector<std::uint64_t> dense_reactions;
    std::map<std::tuple<std::uint32_t, SpeciesId, StateId>, ReservoirDelta> reservoir;
    std::map<std::tuple<std::uint32_t, SpeciesId, StateId>, CachedChannels> dynamic_channels;
    ConservationLedger ledger;
    std::exception_ptr error;
};

struct ChannelResolveContext {
    const MccEngine* engine{nullptr};
    BlockResult* block{nullptr};
    const std::map<std::tuple<std::uint32_t, SpeciesId, StateId>, CachedChannels>* shared{nullptr};
    const std::vector<BackgroundComponent>* components{nullptr};
    std::uint32_t cell{0};
    bool exact_pruning{true};
    ChannelSampler sampler{ChannelSampler::Prefix};
};

} // namespace

struct MccWorkspace::Impl {
    std::shared_ptr<const CompiledModel> model;
    std::vector<CellBackground> background_snapshot;
    std::map<std::uint32_t, std::vector<BackgroundComponent>> by_cell;
    std::map<std::uint32_t, BackgroundIndex> background_indexes;
    std::map<std::tuple<std::uint32_t, SpeciesId, StateId>, CachedChannels> channel_cache;
    std::unordered_map<ReactionId, std::size_t> reaction_index;
    bool exact_pruning{true};
    ChannelSampler sampler{ChannelSampler::Prefix};
    std::vector<ParticleState> snapshot;
    std::vector<std::size_t> active;
    std::vector<std::size_t> eligible;
    std::vector<BlockResult> blocks;
    std::vector<ParticleChange> changes;
    std::vector<CreatedProduct> births;
    std::vector<ParticleState> created;
    StepReport report;
    std::uint64_t largest_id{0};
    Clock::time_point started{};
    Clock::time_point commit_started{};
    bool busy{false};
};

MccWorkspace::MccWorkspace() : impl_(std::make_unique<Impl>()) {}
MccWorkspace::~MccWorkspace() = default;

PreparedMccStep::~PreparedMccStep() {
    if (workspace_ != nullptr) workspace_->impl_->busy = false;
}

PreparedMccStep::PreparedMccStep(PreparedMccStep&& other) noexcept
    : workspace_(other.workspace_), ready_(other.ready_), committed_(other.committed_) {
    other.workspace_ = nullptr;
}

PreparedMccStep& PreparedMccStep::operator=(PreparedMccStep&& other) noexcept {
    if (this != &other) {
        if (workspace_ != nullptr) workspace_->impl_->busy = false;
        workspace_ = other.workspace_;
        ready_ = other.ready_;
        committed_ = other.committed_;
        other.workspace_ = nullptr;
    }
    return *this;
}

const StepReport& PreparedMccStep::report() const {
    if (workspace_ == nullptr) throw Error("prepared MCC step has no workspace");
    return workspace_->impl_->report;
}

std::uint64_t PreparedMccStep::largest_id() const {
    if (workspace_ == nullptr) throw Error("prepared MCC step has no workspace");
    return workspace_->impl_->largest_id;
}

std::vector<BirthKey> PreparedMccStep::birth_keys() const {
    if (workspace_ == nullptr) throw Error("prepared MCC step has no workspace");
    std::vector<BirthKey> keys;
    keys.reserve(workspace_->impl_->births.size());
    for (const CreatedProduct& birth : workspace_->impl_->births) {
        keys.push_back({birth.parent_id, birth.event_index, birth.product_ordinal});
    }
    return keys;
}

void PreparedMccStep::prepare_commit(ParticleAdapter& particles,
                                     const std::vector<std::uint64_t>& child_ids,
                                     const std::uint64_t next_id) {
    if (workspace_ == nullptr || ready_) throw Error("prepared MCC step cannot be committed twice");
    auto& state = *workspace_->impl_;
    state.commit_started = Clock::now();
    if (child_ids.size() != state.births.size() || next_id < state.largest_id) {
        throw Error("invalid prepared MCC child IDs or next ID");
    }
    state.created.clear();
    state.created.reserve(state.births.size());
    for (std::size_t i = 0; i < state.births.size(); ++i) {
        if (child_ids[i] <= state.largest_id ||
            (child_ids[i] >= next_id &&
             !(next_id == UINT64_MAX && child_ids[i] == UINT64_MAX))) {
            throw Error("prepared MCC child ID is outside the reserved range");
        }
        const CreatedProduct& child = state.births[i];
        ParticleState particle;
        particle.species = child.species;
        particle.state = child.state;
        particle.position = child.position;
        particle.velocity = child.velocity;
        particle.weight = child.weight;
        particle.id = child_ids[i];
        particle.birth_step = child.birth_step;
        particle.cell = child.cell;
        state.created.push_back(particle);
    }
    particles.prepare_commit(state.changes, state.created, next_id);
    ready_ = true;
}

void PreparedMccStep::commit(ParticleAdapter& particles) noexcept {
    if (!ready_ || committed_ || workspace_ == nullptr) std::terminate();
    particles.commit();
    auto& state = *workspace_->impl_;
    state.report.commit_seconds = seconds_since(state.commit_started);
    state.report.total_seconds = seconds_since(state.started);
    committed_ = true;
}

StepReport PreparedMccStep::take_report() {
    if (!committed_ || workspace_ == nullptr) throw Error("prepared MCC step was not committed");
    StepReport result = std::move(workspace_->impl_->report);
    workspace_->impl_->busy = false;
    workspace_ = nullptr;
    return result;
}

void VectorParticleAdapter::prepare_commit(
    const std::vector<ParticleChange>& changes,
    const std::vector<ParticleState>& created,
    const std::uint64_t next_id) {
    pending_updates_ = nullptr;
    if (changes.empty() && created.empty()) {
        staged_next_id_ = next_id;
        staged_noop_ = true;
        staged_updates_only_ = false;
        return;
    }
    if (created.empty() && std::all_of(changes.begin(), changes.end(),
        [](const ParticleChange& change) { return change.action == PrimaryAction::Update ||
                                                change.action == PrimaryAction::MoveSpecies; })) {
        pending_updates_ = &changes;
        staged_next_id_ = next_id;
        staged_noop_ = false;
        staged_updates_only_ = true;
        return;
    }
    std::vector<ParticleState> prepared;
    prepared.reserve(particles_.size() + created.size());
    std::size_t change_index = 0;
    for (std::size_t index = 0; index < particles_.size(); ++index) {
        if (change_index < changes.size() && changes[change_index].index == index) {
            if (changes[change_index].action != PrimaryAction::Remove) {
                prepared.push_back(changes[change_index].after);
            }
            ++change_index;
        } else {
            prepared.push_back(particles_[index]);
        }
    }
    prepared.insert(prepared.end(), created.begin(), created.end());
    staged_.swap(prepared);
    staged_next_id_ = next_id;
    staged_noop_ = false;
    staged_updates_only_ = false;
}

void ParticleSoA::reserve(const std::size_t capacity) {
    x.reserve(capacity); y.reserve(capacity); z.reserve(capacity);
    vx.reserve(capacity); vy.reserve(capacity); vz.reserve(capacity);
    weight.reserve(capacity); id.reserve(capacity); birth_step.reserve(capacity);
    state.reserve(capacity); cell.reserve(capacity); alive.reserve(capacity);
}

void ParticleSoA::push(const ParticleState& value) {
    x.push_back(value.position.x); y.push_back(value.position.y); z.push_back(value.position.z);
    vx.push_back(value.velocity.x); vy.push_back(value.velocity.y); vz.push_back(value.velocity.z);
    weight.push_back(value.weight); id.push_back(value.id);
    birth_step.push_back(value.birth_step); state.push_back(value.state);
    cell.push_back(value.cell); alive.push_back(1U);
}

ParticleState ParticleSoA::get(const SpeciesId species, const std::size_t index) const {
    ParticleState result;
    result.species = species;
    result.state = state.at(index);
    result.position = {x.at(index), y.at(index), z.at(index)};
    result.velocity = {vx.at(index), vy.at(index), vz.at(index)};
    result.weight = weight.at(index);
    result.id = id.at(index);
    result.birth_step = birth_step.at(index);
    result.cell = cell.at(index);
    return result;
}

void ParticleSoA::set(const std::size_t index, const ParticleState& value) noexcept {
    x[index] = value.position.x; y[index] = value.position.y; z[index] = value.position.z;
    vx[index] = value.velocity.x; vy[index] = value.velocity.y; vz[index] = value.velocity.z;
    weight[index] = value.weight; id[index] = value.id;
    birth_step[index] = value.birth_step; state[index] = value.state;
    cell[index] = value.cell;
}

void ParticleSoA::compact() noexcept {
    std::size_t write = 0;
    for (std::size_t read = 0; read < size(); ++read) {
        if (!is_alive(read)) continue;
        if (write != read) {
            x[write] = x[read]; y[write] = y[read]; z[write] = z[read];
            vx[write] = vx[read]; vy[write] = vy[read]; vz[write] = vz[read];
            weight[write] = weight[read]; id[write] = id[read];
            birth_step[write] = birth_step[read]; state[write] = state[read];
            cell[write] = cell[read]; alive[write] = 1U;
        }
        ++write;
    }
    x.resize(write); y.resize(write); z.resize(write);
    vx.resize(write); vy.resize(write); vz.resize(write);
    weight.resize(write); id.resize(write); birth_step.resize(write);
    state.resize(write); cell.resize(write); alive.resize(write);
}

ParticleBank::ParticleBank(const CompiledModel& model) {
    for (const Species& species : model.species.all()) {
        if (species.representation == Representation::Kinetic) blocks_.emplace(species.id, ParticleSoA{});
    }
}

void ParticleBank::push(const ParticleState& particle) {
    blocks_.at(particle.species).push(particle);
    if (particle.id == UINT64_MAX) next_id_ = UINT64_MAX;
    else next_id_ = std::max(next_id_, particle.id + 1U);
}

std::size_t ParticleBank::total_size() const noexcept {
    std::size_t result = 0;
    for (const auto& [species, block] : blocks_) {
        (void)species;
        result += block.size();
    }
    return result;
}

SoaParticleAdapter::SoaParticleAdapter(ParticleBank& bank) : bank_(bank) {
    begin_step();
}

void SoaParticleAdapter::begin_step() {
    std::vector<Slot> current;
    current.reserve(bank_.total_size());
    for (const auto& [species, block] : bank_.blocks_) {
        for (std::size_t i = 0; i < block.size(); ++i) current.push_back({species, i});
    }
    slots_.swap(current);
}

bool SoaParticleAdapter::alive(const std::size_t index) const {
    const Slot& slot = slots_.at(index);
    return bank_.blocks_.at(slot.species).is_alive(slot.index);
}

ParticleState SoaParticleAdapter::particle(const std::size_t index) const {
    const Slot& slot = slots_.at(index);
    return bank_.blocks_.at(slot.species).get(slot.species, slot.index);
}

void SoaParticleAdapter::prepare_commit(
    const std::vector<ParticleChange>& changes,
    const std::vector<ParticleState>& created,
    const std::uint64_t next_id) {
    pending_updates_ = nullptr;
    if (changes.empty() && created.empty()) {
        staged_next_id_ = next_id;
        staged_noop_ = true;
        staged_updates_only_ = false;
        return;
    }
    if (created.empty() && std::all_of(changes.begin(), changes.end(),
        [](const ParticleChange& change) { return change.action == PrimaryAction::Update; })) {
        pending_updates_ = &changes;
        staged_next_id_ = next_id;
        staged_noop_ = false;
        staged_updates_only_ = true;
        return;
    }
    std::vector<ParticleChange> staged_changes = changes;
    std::vector<ParticleState> staged_created = created;
    std::map<SpeciesId, std::size_t> additions;
    std::map<SpeciesId, std::size_t> remaining;
    for (const auto& [species, block] : bank_.blocks_) {
        for (std::size_t i = 0; i < block.size(); ++i) {
            if (block.is_alive(i)) ++remaining[species];
        }
    }
    for (const ParticleChange& change : staged_changes) {
        const Slot& slot = slots_.at(change.index);
        if (change.action == PrimaryAction::Remove) {
            --remaining[slot.species];
        } else if (change.action == PrimaryAction::MoveSpecies &&
                   change.after.species != slot.species) {
            --remaining[slot.species];
            ++additions[change.after.species];
        }
    }
    for (const ParticleState& child : staged_created) ++additions[child.species];
    std::vector<Slot> future_slots;
    for (const auto& [species, block] : bank_.blocks_) {
        (void)block;
        if (additions[species] > std::numeric_limits<std::size_t>::max() - remaining[species]) {
            throw Error("particle bank size overflow");
        }
        const std::size_t count = remaining[species] + additions[species];
        for (std::size_t i = 0; i < count; ++i) future_slots.push_back({species, i});
    }
    for (const auto& [species, extra] : additions) {
        ParticleSoA& block = bank_.blocks_.at(species);
        if (extra > std::numeric_limits<std::size_t>::max() - block.size()) {
            throw Error("particle bank capacity overflow");
        }
        block.reserve(block.size() + extra);
    }
    changes_.swap(staged_changes);
    created_.swap(staged_created);
    next_slots_.swap(future_slots);
    staged_next_id_ = next_id;
    staged_noop_ = false;
    staged_updates_only_ = false;
}

void SoaParticleAdapter::commit() noexcept {
    if (staged_noop_) {
        bank_.next_id_ = staged_next_id_;
        return;
    }
    if (staged_updates_only_) {
        for (const ParticleChange& change : *pending_updates_) {
            const Slot& slot = slots_[change.index];
            bank_.blocks_.find(slot.species)->second.set(slot.index, change.after);
        }
        pending_updates_ = nullptr;
        bank_.next_id_ = staged_next_id_;
        return;
    }
    for (const ParticleChange& change : changes_) {
        const Slot& slot = slots_[change.index];
        ParticleSoA& source = bank_.blocks_.find(slot.species)->second;
        if (change.action == PrimaryAction::Remove) {
            source.mark_dead(slot.index);
        } else if (change.after.species == slot.species) {
            source.set(slot.index, change.after);
        } else {
            source.mark_dead(slot.index);
            bank_.blocks_.find(change.after.species)->second.push(change.after);
        }
    }
    for (const ParticleState& child : created_) bank_.blocks_.find(child.species)->second.push(child);
    for (auto& [species, block] : bank_.blocks_) {
        (void)species;
        block.compact();
    }
    slots_.swap(next_slots_);
    bank_.next_id_ = staged_next_id_;
}

// 便捷重载每次新建工作区；连续推进可用另一个重载复用工作区。
StepReport MccStepper::step(ParticleAdapter& particles,
                            const std::vector<CellBackground>& background,
                            const Real dt_s, const std::uint64_t global_step,
                            const std::uint64_t seed) const {
    MccWorkspace workspace;
    return step(particles, background, dt_s, global_step, seed, workspace);
}

StepReport MccStepper::step(ParticleAdapter& particles,
                            const std::vector<CellBackground>& background,
                            const Real dt_s, const std::uint64_t global_step,
                            const std::uint64_t seed, MccWorkspace& workspace) const {
    PreparedMccStep pending = prepare_step(particles, background, dt_s, global_step,
                                          seed, workspace);
    std::vector<std::uint64_t> ids;
    ids.reserve(pending.report().created_particles);
    std::uint64_t next = pending.largest_id();
    for (std::size_t i = 0; i < pending.report().created_particles; ++i) {
        if (next == UINT64_MAX) throw Error("child particle id overflow");
        ids.push_back(++next);
    }
    const std::uint64_t next_id = next == UINT64_MAX ? UINT64_MAX : next + 1U;
    pending.prepare_commit(particles, ids, next_id);
    pending.commit(particles);
    return pending.take_report();
}

// 准备缓存、输入快照和碰撞结果；本函数尚不写回粒子。
PreparedMccStep MccStepper::prepare_step(
    ParticleAdapter& particles, const std::vector<CellBackground>& background,
    const Real dt_s, const std::uint64_t global_step, const std::uint64_t seed,
    MccWorkspace& workspace) const {
    auto& state = *workspace.impl_;
    if (state.busy) throw Error("MCC workspace already has a pending step");
    state.busy = true;
    state.started = Clock::now();
    const auto started = state.started;
    try {
        if (!std::isfinite(dt_s) || dt_s < 0.0) throw Error("batch dt_s must be finite and non-negative");
        if (global_step == std::numeric_limits<std::uint64_t>::max()) {
            throw Error("global_step cannot be UINT64_MAX");
        }
        if (options_.max_candidates_per_particle == 0U) {
            throw Error("max_candidates_per_particle must be positive");
        }
        if (options_.max_candidates_per_particle == UINT32_MAX) {
            throw Error("max_candidates_per_particle must be below UINT32_MAX");
        }
        if (options_.threads > static_cast<unsigned>(std::numeric_limits<int>::max())) {
            throw Error("OpenMP thread count exceeds INT_MAX");
        }
        particles.begin_step();

        // 1. 模型、背景或抽样选项变化时重建缓存，避免沿用过期频率。
        const CompiledModel& model = engine_.model();
        const bool unchanged = state.model.get() == &model &&
            state.exact_pruning == options_.exact_pruning &&
            state.sampler == options_.sampler &&
            state.background_snapshot.size() == background.size() &&
            std::equal(background.begin(), background.end(), state.background_snapshot.begin(),
                       same_background);
        if (!unchanged) {
            state.model.reset();
            state.background_indexes.clear();
            state.by_cell.clear();
            state.channel_cache.clear();
            state.reaction_index.clear();
            for (std::size_t i = 0; i < model.reactions.size(); ++i) {
                state.reaction_index.emplace(model.reactions[i].id, i);
            }
            for (BlockResult& block : state.blocks) block.dynamic_channels.clear();
            std::set<std::tuple<std::uint32_t, SpeciesId, StateId>> background_keys;
            std::map<std::pair<std::uint32_t, SpeciesId>, BackgroundComponent> thermodynamics;
            for (const CellBackground& entry : background) {
            const auto& species = model.species.at(entry.component.species);
            if (species.representation != Representation::Background) {
                throw Error("batch background contains a kinetic species");
            }
            if (entry.component.state != invalid_state &&
                model.states.at(entry.component.state).species != entry.component.species) {
                throw Error("batch background state does not belong to its species");
            }
            if (!std::isfinite(entry.component.density_m3) || entry.component.density_m3 < 0.0 ||
                !std::isfinite(entry.component.temperature_k) || entry.component.temperature_k < 0.0 ||
                !std::isfinite(entry.component.drift_m_per_s.x) ||
                !std::isfinite(entry.component.drift_m_per_s.y) ||
                !std::isfinite(entry.component.drift_m_per_s.z)) {
                throw Error("batch background has a negative or non-finite field");
            }
            const auto key = std::make_tuple(entry.cell, entry.component.species,
                                             entry.component.state);
            if (!background_keys.insert(key).second) {
                throw Error("duplicate batch background cell/species/state");
            }
            const auto thermo_key = std::make_pair(entry.cell, entry.component.species);
            const auto [found, inserted] = thermodynamics.emplace(thermo_key, entry.component);
            if (!inserted && (found->second.temperature_k != entry.component.temperature_k ||
                              found->second.drift_m_per_s.x != entry.component.drift_m_per_s.x ||
                              found->second.drift_m_per_s.y != entry.component.drift_m_per_s.y ||
                              found->second.drift_m_per_s.z != entry.component.drift_m_per_s.z)) {
                throw Error("states of one background species must share temperature and drift");
            }
                state.by_cell[entry.cell].push_back(entry.component);
            }
            state.background_snapshot = background;
            state.exact_pruning = options_.exact_pruning;
            state.sampler = options_.sampler;
            for (const auto& [cell, components] : state.by_cell) {
                state.background_indexes.emplace(cell, engine_.index_background(components));
            }
            state.model = engine_.model_;
        }
        const auto& by_cell = state.by_cell;

        const std::size_t size = particles.size();
        auto& snapshot = state.snapshot;
        snapshot.resize(size);
        auto& active = state.active;
        active.clear();
        active.reserve(size);
        std::uint64_t largest_id = 0;
        bool ordered_ids = true;
        for (std::size_t index = 0; index < size; ++index) {
            if (!particles.alive(index)) continue;
            const ParticleState particle = particles.particle(index);
            const Species& species = model.species.at(particle.species);
            if (species.representation != Representation::Kinetic ||
                model.states.at(particle.state).species != particle.species) {
                throw Error("batch particle has an invalid kinetic species or state");
            }
            if (!std::isfinite(particle.weight) || particle.weight < 0.0 ||
                !std::isfinite(particle.position.x) || !std::isfinite(particle.position.y) ||
                !std::isfinite(particle.position.z) ||
                !std::isfinite(particle.velocity.x) || !std::isfinite(particle.velocity.y) ||
                !std::isfinite(particle.velocity.z)) {
                throw Error("batch particle has invalid position, weight or velocity");
            }
            largest_id = std::max(largest_id, particle.id);
            snapshot[index] = particle;
            if (!active.empty() && snapshot[active.back()].id > particle.id) ordered_ids = false;
            active.push_back(index);
        }
        if (!ordered_ids) {
            std::sort(active.begin(), active.end(), [&](const std::size_t a, const std::size_t b) {
                return snapshot[a].id < snapshot[b].id;
            });
        }
        auto& eligible = state.eligible;
        eligible.clear();
        eligible.reserve(active.size());
        for (std::size_t i = 0; i < active.size(); ++i) {
            if (i > 0 && snapshot[active[i - 1U]].id == snapshot[active[i]].id) {
                throw Error("duplicate batch particle id");
            }
            if (snapshot[active[i]].birth_step <= global_step) eligible.push_back(active[i]);
        }
        const std::uint64_t hinted_id = particles.next_id_hint();
        if (hinted_id > 0U) largest_id = std::max(largest_id, hinted_id - 1U);
        state.largest_id = largest_id;

        const std::vector<BackgroundComponent> empty_background;
        const BackgroundIndex empty_index;
        auto& channel_cache = state.channel_cache;
        bool previous_key_valid = false;
        std::uint32_t previous_cell = 0;
        SpeciesId previous_species = 0;
        StateId previous_state = 0;
        for (const std::size_t index : eligible) {
            const ParticleState& projectile = snapshot[index];
            if (previous_key_valid && projectile.cell == previous_cell &&
                projectile.species == previous_species && projectile.state == previous_state) {
                continue;
            }
            previous_key_valid = true;
            previous_cell = projectile.cell;
            previous_species = projectile.species;
            previous_state = projectile.state;
            const std::uint32_t cache_cell = by_cell.count(projectile.cell) != 0U
                ? projectile.cell : UINT32_MAX;
            const auto key = std::make_tuple(cache_cell, projectile.species, projectile.state);
            if (channel_cache.count(key) != 0U) continue;
            const auto background_it = by_cell.find(cache_cell);
            const auto& components = background_it == by_cell.end()
                ? empty_background : background_it->second;
            channel_cache.emplace(key, engine_.prepare_channels(
                components, projectile.species, projectile.state,
                options_.exact_pruning, options_.sampler));
        }

        // 2. Auto 避免小任务的线程开销和已有并行区中的嵌套并行。
        CpuBackend backend = options_.backend;
        if (backend == CpuBackend::Auto) {
#ifdef _OPENMP
            backend = eligible.size() >= options_.min_parallel_particles && !omp_in_parallel()
                ? CpuBackend::OpenMp : CpuBackend::Serial;
#else
            backend = CpuBackend::Serial;
#endif
        }
#ifndef _OPENMP
        if (backend == CpuBackend::OpenMp) throw Error("OpenMP backend is not compiled in");
#endif
#ifdef _OPENMP
        unsigned threads = 1;
        if (backend == CpuBackend::OpenMp) {
            threads = options_.threads == 0U ? static_cast<unsigned>(omp_get_max_threads())
                                              : options_.threads;
            threads = std::max(1U, std::min<unsigned>(threads,
                static_cast<unsigned>(std::min<std::size_t>(eligible.size(), UINT32_MAX))));
        }
#endif
        if (eligible.size() > static_cast<std::size_t>(std::numeric_limits<long long>::max())) {
            throw Error("batch particle count exceeds the parallel loop limit");
        }
        // 3. 固定大小分块：调度可以变化，块编号和汇总顺序保持固定。
        const std::size_t block_size = 256U;
        const std::size_t block_count = eligible.size() / block_size +
            (eligible.size() % block_size != 0U ? 1U : 0U);
        const bool dense_reactions = model.reactions.size() > 0 &&
            (block_count == 0 || model.reactions.size() <= 4000000U / block_count);
        auto& report = state.report;
        report = StepReport{};
        report.preparation_seconds = seconds_since(started);
        const auto sampling_start = Clock::now();
        auto& blocks = state.blocks;
        blocks.resize(block_count);
        for (std::size_t i = 0; i < block_count; ++i) {
            BlockResult& block = blocks[i];
            block.visited = 0;
            block.candidates = 0;
            block.real_events = 0;
            block.null_events = 0;
            block.changes.clear();
            block.created.clear();
            block.events.clear();
            block.by_reaction.clear();
            if (dense_reactions) block.dense_reactions.assign(model.reactions.size(), 0);
            else block.dense_reactions.clear();
            block.reservoir.clear();
            block.ledger = ConservationLedger{};
            block.error = nullptr;
        }
        // 4. 每块独立记录变化；线程不直接改主程序的粒子数组。
        const auto process = [&](const std::size_t block_index) {
            BlockResult& block = blocks[block_index];
            try {
              bool local_key_valid = false;
              std::uint32_t previous_particle_cell = 0, cached_cell = 0;
              SpeciesId cached_species = 0;
              StateId cached_state = 0;
              const std::vector<BackgroundComponent>* components_ptr = nullptr;
              const BackgroundIndex* background_index_ptr = nullptr;
              const CachedChannels* channels_ptr = nullptr;
              const std::size_t end = std::min(eligible.size(), (block_index + 1U) * block_size);
              for (std::size_t work_index = block_index * block_size; work_index < end;
                   ++work_index) {
                const std::size_t index = eligible[work_index];
                const ParticleState& projectile = snapshot[index];
                if (!local_key_valid || projectile.cell != previous_particle_cell ||
                    projectile.species != cached_species || projectile.state != cached_state) {
                    cached_cell = by_cell.count(projectile.cell) != 0U
                        ? projectile.cell : UINT32_MAX;
                    const auto local = by_cell.find(cached_cell);
                    components_ptr = local == by_cell.end() ? &empty_background : &local->second;
                    const auto indexed = state.background_indexes.find(cached_cell);
                    background_index_ptr = indexed == state.background_indexes.end()
                        ? &empty_index : &indexed->second;
                    channels_ptr = &channel_cache.at(
                        std::make_tuple(cached_cell, projectile.species, projectile.state));
                    previous_particle_cell = projectile.cell;
                    cached_species = projectile.species;
                    cached_state = projectile.state;
                    local_key_valid = true;
                }
                ChannelResolveContext context{&engine_, &block, &channel_cache, components_ptr,
                                              cached_cell, options_.exact_pruning, options_.sampler};
                const auto lookup = +[](void* data, SpeciesId species, StateId state_id)
                    -> const CachedChannels* {
                    auto& current = *static_cast<ChannelResolveContext*>(data);
                    const auto key = std::make_tuple(current.cell, species, state_id);
                    const auto shared = current.shared->find(key);
                    if (shared != current.shared->end()) return &shared->second;
                    const auto dynamic = current.block->dynamic_channels.find(key);
                    if (dynamic != current.block->dynamic_channels.end()) return &dynamic->second;
                    auto compiled = current.engine->prepare_channels(
                        *current.components, species, state_id,
                        current.exact_pruning, current.sampler);
                    return &current.block->dynamic_channels.emplace(key, std::move(compiled))
                        .first->second;
                };
                CollisionRequest request;
                request.projectile = projectile;
                request.background_view = components_ptr;
                request.cached_channels = channels_ptr;
                request.dt_s = dt_s;
                request.global_step = global_step;
                request.seed = seed;
                request.exact_pruning = options_.exact_pruning;
                StepOutcome outcome = engine_.collide_full_batch(
                    request, *background_index_ptr, lookup, &context,
                    options_.max_candidates_per_particle, options_.record_events);
                ++block.visited;
                block.candidates += outcome.candidates;
                block.real_events += outcome.real_events;
                block.null_events += outcome.null_events;
                if (outcome.real_events != 0U) {
                    block.changes.push_back({index, outcome.primary_action, outcome.primary_after});
                    block.created.insert(block.created.end(), outcome.created.begin(),
                                         outcome.created.end());
                    for (const auto& [reaction, count] : outcome.reaction_counts) {
                        if (dense_reactions) {
                            block.dense_reactions[state.reaction_index.at(reaction)] += count;
                        } else {
                            block.by_reaction[reaction] += count;
                        }
                    }
                    for (const ReservoirDelta& delta : outcome.reservoir) {
                        auto& target = block.reservoir[std::make_tuple(
                            projectile.cell, delta.species, delta.state)];
                        add_reservoir(target, delta);
                    }
                    add_ledger(block.ledger, outcome.ledger);
                }
                if (options_.record_events) {
                    for (const EventRecord& event : outcome.events) {
                        block.events.push_back({projectile.id, projectile.cell, event});
                    }
                }
              }
            } catch (...) {
                block.error = std::current_exception();
            }
        };

#ifdef _OPENMP
        if (backend == CpuBackend::OpenMp && threads > 1U) {
#pragma omp parallel num_threads(threads)
            {
#pragma omp for schedule(dynamic, 1)
                for (long long index = 0; index < static_cast<long long>(block_count); ++index) {
                    process(static_cast<std::size_t>(index));
                }
            }
        } else
#endif
        {
            for (std::size_t index = 0; index < block_count; ++index) process(index);
        }
        // 5. 按块编号汇总；块内异常也在并行计算结束后转回主线程。
        report.sampling_seconds = seconds_since(sampling_start);
        const auto reduction_start = Clock::now();
        std::map<ReactionId, std::uint64_t> counts;
        std::vector<std::uint64_t> dense_totals;
        if (dense_reactions) dense_totals.resize(model.reactions.size());
        std::map<std::tuple<std::uint32_t, SpeciesId, StateId>, ReservoirDelta> deltas;
        auto& changes = state.changes;
        changes.clear();
        auto& births = state.births;
        births.clear();
        std::size_t change_capacity = 0, birth_capacity = 0, event_capacity = 0;
        for (std::size_t i = 0; i < block_count; ++i) {
            change_capacity += blocks[i].changes.size();
            birth_capacity += blocks[i].created.size();
            event_capacity += blocks[i].events.size();
        }
        changes.reserve(change_capacity);
        births.reserve(birth_capacity);
        report.events.reserve(event_capacity);
        for (std::size_t block_index = 0; block_index < block_count; ++block_index) {
            BlockResult& block = blocks[block_index];
            if (block.error) std::rethrow_exception(block.error);
            report.particles_visited += block.visited;
            report.candidates += block.candidates;
            report.real_events += block.real_events;
            report.null_events += block.null_events;
            for (ParticleChange& change : block.changes) changes.push_back(std::move(change));
            births.insert(births.end(), block.created.begin(), block.created.end());
            if (dense_reactions) {
                for (std::size_t i = 0; i < dense_totals.size(); ++i) {
                    dense_totals[i] += block.dense_reactions[i];
                }
            } else {
                for (const auto& [reaction, count] : block.by_reaction) counts[reaction] += count;
            }
            for (const auto& [key, delta] : block.reservoir) {
                auto& target = deltas[key];
                add_reservoir(target, delta);
            }
            for (ParticleEvent& event : block.events) report.events.push_back(std::move(event));
            add_ledger(report.ledger, block.ledger);
        }
        report.created_particles = births.size();
        if (dense_reactions) {
            for (std::size_t i = 0; i < dense_totals.size(); ++i) {
                if (dense_totals[i] != 0U) {
                    report.by_reaction.emplace_back(model.reactions[i].id, dense_totals[i]);
                }
            }
            std::sort(report.by_reaction.begin(), report.by_reaction.end());
        } else {
            for (const auto& [reaction, count] : counts) report.by_reaction.emplace_back(reaction, count);
        }
        for (const auto& [key, delta] : deltas) {
            require_finite(delta.physical_particles, "reservoir count");
            require_finite(delta.kinetic_energy_j, "reservoir kinetic energy");
            require_finite(delta.internal_energy_j, "reservoir internal energy");
            require_finite(delta.momentum_kg_m_per_s.x, "reservoir momentum");
            require_finite(delta.momentum_kg_m_per_s.y, "reservoir momentum");
            require_finite(delta.momentum_kg_m_per_s.z, "reservoir momentum");
            report.reservoir.push_back(CellReservoirDelta{std::get<0>(key), delta});
        }
        const Real ledger_scalars[] = {
            report.ledger.charge_before_c, report.ledger.charge_after_c,
            report.ledger.momentum_before_kg_m_per_s.x,
            report.ledger.momentum_before_kg_m_per_s.y,
            report.ledger.momentum_before_kg_m_per_s.z,
            report.ledger.momentum_after_kg_m_per_s.x,
            report.ledger.momentum_after_kg_m_per_s.y,
            report.ledger.momentum_after_kg_m_per_s.z,
            report.ledger.kinetic_before_j, report.ledger.kinetic_after_j,
            report.ledger.internal_before_j, report.ledger.internal_after_j,
            report.ledger.released_energy_j,
            report.ledger.radiated_or_unresolved_j,
            report.ledger.energy_residual_j, report.ledger.tolerance_j};
        for (const Real value : ledger_scalars) require_finite(value, "conservation ledger");
        if (!ordered_ids) {
            std::sort(changes.begin(), changes.end(), [](const auto& a, const auto& b) {
                return a.index < b.index;
            });
        }
        report.reduction_seconds = seconds_since(reduction_start);

        return PreparedMccStep(workspace);
    } catch (...) {
        state.busy = false;
        throw;
    }
}

} // namespace algoplasma::mcc
