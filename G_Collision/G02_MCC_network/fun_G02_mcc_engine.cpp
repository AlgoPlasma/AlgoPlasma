// SPDX-License-Identifier: Apache-2.0
// 阅读导引：输入校验/通道准备 → 背景抽样/末态构造 → 守恒检查 → 公开接口。
// 第一次阅读可先跳到 collide_impl，看标有“步骤”的主流程，再回看辅助函数。
// MCC（Monte Carlo Collision，蒙特卡洛碰撞）用概率抽样推进碰撞，不推进位置。
// Method basis: Skullerud (1968), doi:10.1088/0022-3727/1/11/423;
// Vahedi & Surendra (1995), doi:10.1016/0010-4655(94)00171-W.
// Clock/channel and thermal-partner mapping (including assumptions):
// docs/source/rst_files/G_Collision/G02_MCC_network/references.rst.
#include "engine.hpp"

#include "kinematics.hpp"
#include "rng.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace algoplasma {
namespace mcc {
namespace {

// ── 随机流与输入准备 ──
// 时间、通道、接受判定和末态各用独立 slot；修改某一步取数次数不串扰其他用途。
// RNG slots. They are part of the replay contract and must never depend on
// thread, rank or input order.
constexpr std::uint64_t slot_clock = 0x01;
constexpr std::uint64_t slot_select = 0x02;
constexpr std::uint64_t slot_real = 0x03;
constexpr std::uint64_t slot_final = 0x04;
constexpr std::uint64_t slot_background_base = 0x100;

struct PreparedRequest {
    BackgroundIndex components;
    const BackgroundIndex* borrowed_components{nullptr};
    std::uint32_t max_events{64};
    bool exact_pruning{false};
    [[nodiscard]] const BackgroundIndex& components_view() const noexcept {
        return borrowed_components == nullptr ? components : *borrowed_components;
    }
};

[[nodiscard]] std::uint32_t background_key(const SpeciesId species,
                                           const StateId state) noexcept {
    return (static_cast<std::uint32_t>(species) << 16U) | state;
}

// 优先匹配“物种 + 能级”；找不到时回退到该物种的汇总背景 invalid_state。
[[nodiscard]] const BackgroundComponent* find_background(
    const std::unordered_map<std::uint32_t, const BackgroundComponent*>& components,
    const SpeciesId species, const StateId state) {
    const auto exact = components.find(background_key(species, state));
    if (exact != components.end()) return exact->second;
    const auto aggregate = components.find(background_key(species, invalid_state));
    return aggregate == components.end() ? nullptr : aggregate->second;
}

[[nodiscard]] Real kinetic_energy(const Real mass, const Vec3 velocity) {
    return 0.5 * mass * dot(velocity, velocity);
}

void require_finite_vec3(const Vec3 value, const std::string& context) {
    if (!is_finite(value.x) || !is_finite(value.y) || !is_finite(value.z)) {
        throw Error(context + " is NaN or infinite");
    }
}

// Maxwell（麦克斯韦）热速度：每个分量的标准差 sqrt(k_B*T/m)。
// 漂移速度是整体平均运动；T=0 时只有漂移，没有热涨落。
[[nodiscard]] Vec3 sample_maxwellian_velocity(const Species& species,
                                              const BackgroundComponent& background,
                                              CounterRng& rng) {
    if (!(background.temperature_k > 0.0)) {
        require_finite_vec3(background.drift_m_per_s, "background drift velocity");
        return background.drift_m_per_s;
    }
    const Real standard_deviation =
        std::sqrt(boltzmann_j_per_k * background.temperature_k / species.mass_kg);
    const Vec3 sampled =
        background.drift_m_per_s +
        Vec3{standard_deviation * rng.normal(), standard_deviation * rng.normal(),
             standard_deviation * rng.normal()};
    require_finite_vec3(sampled, "sampled background velocity");
    return sampled;
}

void validate_particle(const CompiledModel& model, const ParticleState& particle,
                       const std::string& role) {
    const Species& species = model.species.at(particle.species);
    if (species.representation != Representation::Kinetic) {
        throw Error(role + " species '" + species.name +
                    "' is not a kinetic species");
    }
    const State& state = model.states.at(particle.state);
    if (state.species != particle.species) {
        throw Error(role + " state '" + state.label + "' does not belong to species '" +
                    species.name + "'");
    }
    if (!is_finite(particle.weight) || particle.weight < 0.0) {
        throw Error(role + " weight must be finite and non-negative");
    }
    if (!is_finite(particle.velocity.x) || !is_finite(particle.velocity.y) ||
        !is_finite(particle.velocity.z)) {
        throw Error(role + " velocity is NaN or infinite");
    }
}

// 两体反应频率为 n*k，三体为 n1*n2*k；密度按化学计量数重复相乘。
// 此函数只求背景密度乘积，入射模拟粒子的 weight 不放进其碰撞频率。
[[nodiscard]] Real density_product_for(const CompiledReaction& reaction,
                                       const std::unordered_map<std::uint32_t,
                                                                 const BackgroundComponent*>& components) {
    Real product = 1.0;
    for (const ReactantTerm& term : reaction.reactants) {
        if (term.role != ReactantRole::Background) continue;
        const BackgroundComponent* component = find_background(components, term.species, term.state);
        if (component == nullptr) {
            throw Error("reaction '" + reaction.name + "' requires background species '" +
                        std::to_string(term.species) + "' which is missing from the request");
        }
        for (unsigned i = 0; i < term.stoichiometry; ++i) {
            product *= component->density_m3;
            if (!is_finite(product)) {
                throw Error("reaction '" + reaction.name +
                            "' density product overflowed to infinity");
            }
        }
    }
    return product;
}

[[nodiscard]] PreparedRequest prepare_request(const CompiledModel& model,
                                              const CollisionRequest& request,
                                              const BackgroundIndex* borrowed = nullptr) {
    if (!is_finite(request.dt_s) || request.dt_s < 0.0) {
        throw Error("collision request dt_s must be finite and non-negative");
    }
    validate_particle(model, request.projectile, "projectile");

    PreparedRequest prepared;
    prepared.borrowed_components = borrowed;
    if (borrowed == nullptr) {
        const auto& backgrounds = request.background_view == nullptr
            ? request.background : *request.background_view;
        for (const BackgroundComponent& component : backgrounds) {
            const Species& species = model.species.at(component.species);
            if (species.representation != Representation::Background) {
                throw Error("background component '" + species.name +
                            "' is not a background species");
            }
            if (component.state != invalid_state &&
                model.states.at(component.state).species != component.species) {
                throw Error("background state does not belong to its species");
            }
            const auto key = background_key(component.species, component.state);
            if (prepared.components.count(key) != 0U) {
                throw Error("background species '" + species.name +
                            "' is listed more than once in the request");
            }
            if (!is_finite(component.density_m3) || component.density_m3 < 0.0) {
                throw Error("background species '" + species.name +
                            "' has a negative or non-finite density");
            }
            if (!is_finite(component.temperature_k) || component.temperature_k < 0.0) {
                throw Error("background species '" + species.name +
                            "' has a negative or non-finite temperature");
            }
            if (!is_finite(component.drift_m_per_s.x) || !is_finite(component.drift_m_per_s.y) ||
                !is_finite(component.drift_m_per_s.z)) {
                throw Error("background species '" + species.name +
                            "' has a non-finite drift velocity");
            }
            prepared.components.emplace(key, &component);
        }
    }
    prepared.max_events = request.max_events_per_step != 0U
        ? request.max_events_per_step
        : model.options.max_events_per_step;
    prepared.exact_pruning = request.exact_pruning;
    return prepared;
}

// 通道按当前主粒子的物种和能级选择。majorant 为频率的保守上界 [s^-1]：
// 编译期得到速率形状上界，运行时乘背景密度；只剔除严格零密度的通道。
// Active channels are the reactions whose declared kinetic projectile is the
// exact (species, state) pair of the current primary particle. Background
// densities are only required for those active channels.
[[nodiscard]] std::vector<PreparedChannel> build_active_channels(
    const CompiledModel& model, const PreparedRequest& prepared,
    const SpeciesId projectile_species, const StateId projectile_state) {
    std::vector<PreparedChannel> channels;
    for (const std::size_t index :
         model.reactions_for_projectile_view(projectile_species, projectile_state)) {
        const CompiledReaction& reaction = model.reactions[index];
        PreparedChannel channel;
        channel.index = index;
        channel.density_product = density_product_for(reaction, prepared.components_view());
        if (prepared.exact_pruning && channel.density_product == 0.0) continue;
        channel.majorant_s_inv = reaction.majorant_shape * reaction.applied_majorant_scale *
                                 channel.density_product;
        if (!is_finite(channel.majorant_s_inv)) {
            throw Error("reaction '" + reaction.name +
                        "' channel majorant overflowed to infinity");
        }
        for (const ReactantTerm& term : reaction.reactants) {
            if (term.role == ReactantRole::Background) {
                channel.diagnostic_background = term.species;
                break;
            }
        }
        channels.push_back(channel);
    }
    return channels;
}

[[nodiscard]] Real total_majorant_for(const std::vector<PreparedChannel>& channels) {
    Real total = 0.0;
    for (const PreparedChannel& channel : channels) {
        total += channel.majorant_s_inv;
    }
    if (!is_finite(total)) {
        throw Error("the total collision majorant overflowed to infinity");
    }
    return total;
}

struct SampledBodies {
    std::vector<Vec3> velocities; // aligned with reaction.reactant_bodies
};

// 显式粒子沿用当前速度；背景反应物从热分布抽样。
// 同一物种出现多次时用 occurrence 分开随机流，避免抽成完全相同的速度。
[[nodiscard]] SampledBodies sample_reactant_bodies(
    const CompiledModel& model, const CompiledReaction& reaction,
    const ParticleState& primary,
    const std::unordered_map<std::uint32_t, const BackgroundComponent*>& components,
    const CollisionRequest& request, const std::uint32_t event_index) {
    SampledBodies sampled;
    sampled.velocities.resize(reaction.reactant_bodies.size());
    std::unordered_map<SpeciesId, unsigned> occurrence;
    bool projectile_assigned = false;
    for (std::size_t i = 0; i < reaction.reactant_bodies.size(); ++i) {
        const SpeciesId species_id = reaction.reactant_bodies[i].first;
        if (!projectile_assigned && species_id == reaction.projectile) {
            sampled.velocities[i] = primary.velocity;
            projectile_assigned = true;
            continue;
        }
        const BackgroundComponent* component = find_background(
            components, species_id, reaction.reactant_bodies[i].second);
        if (component == nullptr) {
            throw Error("reaction '" + reaction.name + "' has an unresolved background reactant");
        }
        const Species& type = model.species.at(species_id);
        const unsigned copy = occurrence[species_id]++;
        CounterRng rng(request.seed, request.global_step, primary.id, event_index,
                       CounterRng::stream_slot(slot_background_base + copy, species_id));
        sampled.velocities[i] = sample_maxwellian_velocity(type, *component, rng);
    }
    return sampled;
}

// ── 碰后速度：按已校验的反应类型选择运动学模型 ──
// 输入是整次反应的总动量与可用动能；eV 在此乘元电荷数值转换为 J。
[[nodiscard]] FinalState build_final_state(const CompiledModel& model,
                                           const CompiledReaction& reaction,
                                           const ParticleState& primary,
                                           const SampledBodies& sampled,
                                           const Vec3 total_momentum,
                                           const Real available_kinetic_j,
                                           CounterRng& rng) {
    const Real energy_scale = elementary_charge_c;
    const Real ker_j = reaction.ker_min_ev * energy_scale;
    std::vector<Real> masses;
    masses.reserve(reaction.product_bodies.size());
    for (const auto& body : reaction.product_bodies) {
        masses.push_back(model.species.at(body.first).mass_kg);
    }

    if (reaction.resonant) {
        // Strict 2->2 identity exchange (validated at compile time). The mapping
        // is defined by product species, never by products.csv row order: the
        // product with the projectile species takes the background body's
        // velocity and the product with the background species takes the
        // projectile velocity.
        SpeciesId background_species = invalid_species;
        Vec3 background_velocity{};
        for (std::size_t i = 0; i < reaction.reactant_bodies.size(); ++i) {
            if (reaction.reactant_bodies[i].first != reaction.projectile) {
                background_species = reaction.reactant_bodies[i].first;
                background_velocity = sampled.velocities[i];
                break;
            }
        }
        if (background_species == invalid_species) {
            throw Error("reaction '" + reaction.name +
                        "' identity exchange has no background reactant");
        }
        FinalState state;
        state.velocities.resize(reaction.product_bodies.size());
        for (std::size_t i = 0; i < reaction.product_bodies.size(); ++i) {
            const SpeciesId product_species = reaction.product_bodies[i].first;
            if (product_species == reaction.projectile) {
                state.velocities[i] = background_velocity;
            } else if (product_species == background_species) {
                state.velocities[i] = primary.velocity;
            } else {
                throw Error("reaction '" + reaction.name +
                            "' identity exchange product does not match a reactant species");
            }
        }
        return state;
    }
    if (reaction.product_bodies.size() == 1U) {
        return single_product_final_state(masses.front(), total_momentum, available_kinetic_j);
    }
    if (reaction.energy_model == EnergyModel::EqualShare) {
        return equal_share_final_state(masses, total_momentum, available_kinetic_j, ker_j, rng);
    }
    if (reaction.product_bodies.size() == 2U) {
        // The relative-velocity axis is only used by the cone model; it is the
        // incoming projectile minus a background body.
        Vec3 relative_axis{};
        for (std::size_t i = 0; i < reaction.reactant_bodies.size(); ++i) {
            if (reaction.reactant_bodies[i].first != reaction.projectile) {
                relative_axis = primary.velocity - sampled.velocities[i];
                break;
            }
        }
        return two_body_final_state(masses[0], masses[1], total_momentum, relative_axis,
                                    available_kinetic_j, ker_j, reaction.angular_model,
                                    reaction.angular_cos_min, reaction.angular_cos_max, rng);
    }
    return n_body_phase_space_final_state(masses, total_momentum, available_kinetic_j, ker_j,
                                          rng);
}

void append_event_ledger(ConservationLedger& ledger, const ConservationLedger& event) {
    ledger.charge_before_c += event.charge_before_c;
    ledger.charge_after_c += event.charge_after_c;
    ledger.momentum_before_kg_m_per_s += event.momentum_before_kg_m_per_s;
    ledger.momentum_after_kg_m_per_s += event.momentum_after_kg_m_per_s;
    ledger.kinetic_before_j += event.kinetic_before_j;
    ledger.kinetic_after_j += event.kinetic_after_j;
    ledger.internal_before_j += event.internal_before_j;
    ledger.internal_after_j += event.internal_after_j;
    ledger.released_energy_j += event.released_energy_j;
    ledger.radiated_or_unresolved_j += event.radiated_or_unresolved_j;
    ledger.energy_residual_j += event.energy_residual_j;
    ledger.tolerance_j += event.tolerance_j;
}

void require_finite_accumulated_ledger(const ConservationLedger& ledger) {
    const Real values[] = {
        ledger.charge_before_c,
        ledger.charge_after_c,
        ledger.momentum_before_kg_m_per_s.x,
        ledger.momentum_before_kg_m_per_s.y,
        ledger.momentum_before_kg_m_per_s.z,
        ledger.momentum_after_kg_m_per_s.x,
        ledger.momentum_after_kg_m_per_s.y,
        ledger.momentum_after_kg_m_per_s.z,
        ledger.kinetic_before_j,
        ledger.kinetic_after_j,
        ledger.internal_before_j,
        ledger.internal_after_j,
        ledger.released_energy_j,
        ledger.radiated_or_unresolved_j,
        ledger.energy_residual_j,
        ledger.tolerance_j};
    for (const Real value : values) {
        if (!is_finite(value)) {
            throw Error("accumulated conservation ledger is NaN or infinite");
        }
    }
}

// ── 守恒检查：反应物、产物和未解析能量必须一起记账 ──
// 电荷/元素检查反应式，动量/能量检查抽到的具体末态；失败直接报错。
void verify_event(const CompiledModel& model, const CompiledReaction& reaction,
                  const ConservationLedger& ledger, const Real relative_tolerance) {
    const auto require_finite = [&reaction](const Real value, const char* name) {
        if (!is_finite(value)) {
            throw Error("reaction '" + reaction.name + "' produced a non-finite " +
                        std::string(name) + " term");
        }
    };
    require_finite(ledger.charge_before_c, "charge-before");
    require_finite(ledger.charge_after_c, "charge-after");
    require_finite(ledger.momentum_before_kg_m_per_s.x, "momentum-before");
    require_finite(ledger.momentum_before_kg_m_per_s.y, "momentum-before");
    require_finite(ledger.momentum_before_kg_m_per_s.z, "momentum-before");
    require_finite(ledger.momentum_after_kg_m_per_s.x, "momentum-after");
    require_finite(ledger.momentum_after_kg_m_per_s.y, "momentum-after");
    require_finite(ledger.momentum_after_kg_m_per_s.z, "momentum-after");
    require_finite(ledger.kinetic_before_j, "kinetic-before");
    require_finite(ledger.kinetic_after_j, "kinetic-after");
    require_finite(ledger.internal_before_j, "internal-before");
    require_finite(ledger.internal_after_j, "internal-after");
    require_finite(ledger.released_energy_j, "released-energy");
    require_finite(ledger.radiated_or_unresolved_j, "radiated/unresolved-energy");
    require_finite(ledger.energy_residual_j, "energy-residual");
    require_finite(ledger.tolerance_j, "energy-tolerance");
    require_finite(relative_tolerance, "relative-tolerance");

    if (ledger.charge_before_c != ledger.charge_after_c) {
        throw Error("reaction '" + reaction.name + "' failed the charge conservation check");
    }
    // Element balance is guaranteed at compile time; re-check the declared
    // inventory at runtime so a corrupted compiled model cannot slip through.
    std::map<std::string, long long> balance;
    for (const auto& body : reaction.reactant_bodies) {
        const auto found = model.composition.find(body.first);
        if (found == model.composition.end()) continue;
        for (const auto& [element, count] : found->second) {
            balance[element] += static_cast<long long>(count);
        }
    }
    for (const auto& body : reaction.product_bodies) {
        const auto found = model.composition.find(body.first);
        if (found == model.composition.end()) continue;
        for (const auto& [element, count] : found->second) {
            balance[element] -= static_cast<long long>(count);
        }
    }
    for (const auto& [element, residual] : balance) {
        if (residual != 0) {
            throw Error("reaction '" + reaction.name + "' failed the element conservation check "
                        "for '" + element + "'");
        }
    }
    const Real momentum_before = norm(ledger.momentum_before_kg_m_per_s);
    const Real momentum_after = norm(ledger.momentum_after_kg_m_per_s);
    const Real momentum_error = norm(ledger.momentum_after_kg_m_per_s -
                                     ledger.momentum_before_kg_m_per_s);
    require_finite(momentum_before, "momentum-before norm");
    require_finite(momentum_after, "momentum-after norm");
    require_finite(momentum_error, "momentum residual");
    const Real momentum_tolerance = relative_tolerance * (momentum_before + momentum_after + 1.0e-30);
    require_finite(momentum_tolerance, "momentum tolerance");
    if (momentum_error > momentum_tolerance) {
        throw Error("reaction '" + reaction.name + "' failed the momentum conservation check");
    }
    if (std::fabs(ledger.energy_residual_j) > ledger.tolerance_j) {
        throw Error("reaction '" + reaction.name + "' failed the energy conservation check "
                    "(residual " + std::to_string(ledger.energy_residual_j) + " J)");
    }
}

} // namespace

const char* to_string(const PrimaryAction value) noexcept {
    switch (value) {
    case PrimaryAction::None: return "none";
    case PrimaryAction::Update: return "update";
    case PrimaryAction::Remove: return "remove";
    case PrimaryAction::MoveSpecies: return "move_species";
    }
    return "unknown";
}

// ── 公开入口与可复用通道缓存 ──
MccEngine::MccEngine(CompiledModel model)
    : model_(std::make_shared<const CompiledModel>(std::move(model))) {}

MccEngine MccEngine::load(const std::filesystem::path& package_dir, CompileOptions options) {
    return MccEngine(compile_model(load_model_package(package_dir), options));
}

SpeciesId MccEngine::species_id(const std::string& name) const {
    return model_->species.id_of(name);
}

StateId MccEngine::state_id(const SpeciesId species, const std::string& label) const {
    return model_->states.find(species, label);
}

std::string MccEngine::species_name(const SpeciesId species) const {
    return model_->species.at(species).name;
}

// 温度速率表可直接给出频率；截面表需先抽背景速度，故此处仅给其上界。
std::vector<ChannelDiagnostics> MccEngine::evaluate_channels(
    const CollisionRequest& request) const {
    const CompiledModel& model = *model_;
    const PreparedRequest prepared = prepare_request(model, request);
    const std::vector<PreparedChannel> channels = build_active_channels(
        model, prepared, request.projectile.species, request.projectile.state);
    std::vector<ChannelDiagnostics> diagnostics;
    diagnostics.reserve(channels.size());
    for (const PreparedChannel& channel : channels) {
        const CompiledReaction& reaction = model.reactions[channel.index];
        ChannelDiagnostics entry;
        entry.reaction = reaction.id;
        entry.algorithm = reaction.algorithm;
        entry.rate_kind = reaction.rate_kind;
        entry.majorant_s_inv = channel.majorant_s_inv;
        if (reaction.rate_kind == RateKind::RateCoefficient) {
            StateId x_state = invalid_state;
            for (const ReactantTerm& term : reaction.reactants) {
                if (term.role == ReactantRole::Background &&
                    term.species == reaction.x_species) {
                    x_state = term.state;
                    break;
                }
            }
            const BackgroundComponent* component = find_background(
                prepared.components_view(), reaction.x_species, x_state);
            if (component == nullptr) {
                throw Error("reaction '" + reaction.name + "' is missing its x_species background");
            }
            bool outside = false;
            const Real coefficient = reaction.table.sample(component->temperature_k, outside);
            if (!is_finite(coefficient)) {
                throw Error("reaction '" + reaction.name +
                            "' sampled a non-finite rate coefficient");
            }
            entry.rate_defined = true;
            entry.rate_s_inv = channel.density_product * coefficient;
            if (!is_finite(entry.rate_s_inv)) {
                throw Error("reaction '" + reaction.name +
                            "' instantaneous rate overflowed to infinity");
            }
        }
        diagnostics.push_back(entry);
    }
    return diagnostics;
}

StepOutcome MccEngine::collide(const CollisionRequest& request) const {
    return collide_impl(request, false, 0U, true);
}

StepOutcome MccEngine::collide_full(const CollisionRequest& request,
                                    const std::uint32_t max_candidates,
                                    const bool record_events) const {
    if (max_candidates == 0U || max_candidates == UINT32_MAX) {
        throw Error("max_candidates must be in [1, UINT32_MAX - 1]");
    }
    return collide_impl(request, true, max_candidates, record_events);
}

// Prefix 保存累计上界，选通道时二分查找；Alias 用额外预处理换常数步数查找。
// 两者权重都是 nu_max,j / sum(nu_max,j)，不会改变目标反应概率。
CachedChannels MccEngine::prepare_channels(
    const std::vector<BackgroundComponent>& background,
    const SpeciesId species, const StateId state,
    const bool exact_pruning, const ChannelSampler sampler) const {
    CollisionRequest request;
    request.projectile.species = species;
    request.projectile.state = state;
    request.background_view = &background;
    request.exact_pruning = exact_pruning;
    const PreparedRequest prepared = prepare_request(*model_, request);
    CachedChannels result;
    result.species = species;
    result.state = state;
    result.channels = build_active_channels(*model_, prepared, species, state);
    result.total_majorant = total_majorant_for(result.channels);
    Real cumulative = 0.0;
    result.cumulative_majorants.reserve(result.channels.size());
    for (const PreparedChannel& channel : result.channels) {
        cumulative += channel.majorant_s_inv;
        result.cumulative_majorants.push_back(cumulative);
    }
    if (sampler == ChannelSampler::Alias && result.total_majorant > 0 &&
        !result.channels.empty()) {
        const std::size_t count = result.channels.size();
        result.alias_probability.resize(count);
        result.alias_index.resize(count);
        std::vector<long double> scaled(count);
        std::vector<std::size_t> small, large;
        small.reserve(count);
        large.reserve(count);
        for (std::size_t i = 0; i < count; ++i) {
            scaled[i] = static_cast<long double>(result.channels[i].majorant_s_inv) *
                static_cast<long double>(count) /
                static_cast<long double>(result.total_majorant);
            result.alias_index[i] = i;
            if (scaled[i] < 1) small.push_back(i);
            else large.push_back(i);
        }
        // 把概率不足一格的通道与概率过剩的通道配对，每格只需记一个备用通道。
        while (!small.empty() && !large.empty()) {
            const std::size_t low = small.back();
            const std::size_t high = large.back();
            small.pop_back();
            large.pop_back();
            result.alias_probability[low] = static_cast<Real>(clamp(
                static_cast<Real>(scaled[low]), 0.0, 1.0));
            result.alias_index[low] = high;
            scaled[high] += scaled[low] - 1;
            if (scaled[high] < 1) small.push_back(high);
            else large.push_back(high);
        }
        for (const std::size_t index : small) result.alias_probability[index] = 1;
        for (const std::size_t index : large) result.alias_probability[index] = 1;
    }
    return result;
}

BackgroundIndex MccEngine::index_background(
    const std::vector<BackgroundComponent>& background) const {
    BackgroundIndex result;
    result.reserve(background.size());
    for (const BackgroundComponent& component : background) {
        result.emplace(background_key(component.species, component.state), &component);
    }
    return result;
}

StepOutcome MccEngine::collide_full_batch(
    const CollisionRequest& request, const BackgroundIndex& background_index,
    const ChannelCacheLookup lookup, void* lookup_context,
    const std::uint32_t max_candidates, const bool record_events) const {
    if (max_candidates == 0U || max_candidates == UINT32_MAX) {
        throw Error("max_candidates must be in [1, UINT32_MAX - 1]");
    }
    return collide_impl(request, true, max_candidates, record_events,
                        &background_index, lookup, lookup_context);
}

// ── 主流程：候选时刻 → 通道 → 背景速度 → 接受/拒绝 → 末态与守恒 ──
// 主粒子 primary 沿当前身份继续推进；额外产物记录为下一步出生，不在此递归推进。
StepOutcome MccEngine::collide_impl(const CollisionRequest& request,
                                   const bool complete_step,
                                   const std::uint32_t max_candidates,
                                   const bool record_events,
                                   const BackgroundIndex* background_index,
                                   const ChannelCacheLookup cache_lookup,
                                   void* cache_context) const {
    const CompiledModel& model = *model_;
    const PreparedRequest prepared = prepare_request(model, request, background_index);

    StepOutcome outcome;
    outcome.primary_after = request.projectile;

    // 步骤 1：取得当前物种/能级的通道。批量调用可借用缓存，单粒子调用自行构造。
    const CachedChannels* cached = request.cached_channels;
    if (cached != nullptr && (cached->species != request.projectile.species ||
                              cached->state != request.projectile.state)) {
        throw Error("batch channel cache does not match projectile species/state");
    }
    std::vector<PreparedChannel> owned_channels;
    if (cached == nullptr) {
        owned_channels = build_active_channels(
            model, prepared, request.projectile.species, request.projectile.state);
    }
    const std::vector<PreparedChannel>* channels = cached == nullptr
        ? &owned_channels : &cached->channels;
    Real total_majorant = cached == nullptr
        ? total_majorant_for(*channels) : cached->total_majorant;

    if (!(total_majorant > 0.0) || !(request.dt_s > 0.0) ||
        (!complete_step && prepared.max_events == 0U)) {
        return outcome;
    }

    Real remaining = request.dt_s;
    const Real energy_scale = elementary_charge_c;
    for (std::uint32_t event_index = 0;; ++event_index) {
        if (!complete_step && outcome.candidates >= prepared.max_events) {
            outcome.event_limit_reached = true;
            break;
        }
        if (channels->empty() || !(total_majorant > 0.0)) break;

        // 步骤 2：总上界 nu_max 对应指数等待时间 tau=-ln(1-U)/nu_max。
        // 先生成比真实碰撞更频繁的候选事件；候选落在本时间步之外就结束。
        CounterRng clock_rng(request.seed, request.global_step, request.projectile.id,
                             event_index, slot_clock);
        const Real uniform = clock_rng.uniform_open();
        const Real time_to_event = -std::log1p(-uniform) / total_majorant;
        if (!(time_to_event <= remaining)) break; // includes infinite time_to_event
        if (complete_step && outcome.candidates >= max_candidates) {
            throw Error("max_candidates exceeded before completing the collision step");
        }
        remaining -= time_to_event;

        // 步骤 3：按各通道上界占总上界的比例选反应，尚不代表反应真的发生。
        CounterRng select_rng(request.seed, request.global_step, request.projectile.id,
                              event_index, slot_select);
        const Real selection = select_rng.uniform_open();
        std::size_t chosen = channels->size() - 1U;
        if (cached != nullptr && channels == &cached->channels &&
            cached->alias_probability.size() == channels->size() &&
            !channels->empty()) {
            const Real scaled = selection * static_cast<Real>(channels->size());
            const std::size_t column = std::min(channels->size() - 1U,
                static_cast<std::size_t>(scaled));
            chosen = scaled - static_cast<Real>(column) < cached->alias_probability[column]
                ? column : cached->alias_index[column];
        } else if (cached != nullptr && channels == &cached->channels) {
            const Real selector = selection * total_majorant;
            const auto found = std::upper_bound(cached->cumulative_majorants.begin(),
                                                cached->cumulative_majorants.end(), selector);
            if (found != cached->cumulative_majorants.end()) {
                chosen = static_cast<std::size_t>(found - cached->cumulative_majorants.begin());
            }
        } else {
            const Real selector = selection * total_majorant;
            Real cumulative = 0.0;
            for (std::size_t i = 0; i < channels->size(); ++i) {
                cumulative += (*channels)[i].majorant_s_inv;
                if (selector < cumulative) {
                    chosen = i;
                    break;
                }
            }
        }
        const PreparedChannel& channel = (*channels)[chosen];
        const CompiledReaction& reaction = model.reactions[channel.index];

        // 步骤 4：为本候选抽背景粒子速度，计算相对速度和真实碰撞频率。
        const ParticleState primary = outcome.primary_after;
        const SampledBodies sampled = sample_reactant_bodies(
            model, reaction, primary, prepared.components_view(), request, event_index);

        // Total momentum and kinetic energy of all reactant bodies.
        Vec3 total_momentum{};
        Real kinetic_before_j = 0.0;
        for (std::size_t i = 0; i < reaction.reactant_bodies.size(); ++i) {
            const Real mass = model.species.at(reaction.reactant_bodies[i].first).mass_kg;
            require_finite_vec3(sampled.velocities[i], "reactant velocity");
            total_momentum += sampled.velocities[i] * mass;
            kinetic_before_j += kinetic_energy(mass, sampled.velocities[i]);
        }
        require_finite_vec3(total_momentum, "total reactant momentum");
        if (!is_finite(kinetic_before_j)) {
            throw Error("reaction '" + reaction.name +
                        "' total reactant kinetic energy is not finite");
        }

        // Physical rate of the selected channel.
        Real actual_rate = 0.0;
        bool outside_domain = false;
        bool has_relative_energy = false;
        bool has_cross_section = false;
        Real relative_energy_ev = 0.0;
        Real sigma_m2 = 0.0;
        if (reaction.rate_kind == RateKind::CrossSection) {
            std::size_t background_index = reaction.reactant_bodies.size();
            for (std::size_t i = 0; i < reaction.reactant_bodies.size(); ++i) {
                if (reaction.reactant_bodies[i].first != reaction.projectile) {
                    background_index = i;
                    break;
                }
            }
            if (background_index == reaction.reactant_bodies.size()) {
                throw Error("reaction '" + reaction.name + "' has no background body");
            }
            const SpeciesId background_species = reaction.reactant_bodies[background_index].first;
            const BackgroundComponent* component = find_background(
                prepared.components_view(), background_species,
                reaction.reactant_bodies[background_index].second);
            if (component == nullptr) {
                throw Error("reaction '" + reaction.name + "' is missing its background component");
            }
            const Real mass1 = model.species.at(reaction.projectile).mass_kg;
            const Real mass2 = model.species.at(background_species).mass_kg;
            const Real reduced = mass1 * mass2 / (mass1 + mass2);
            const Vec3 relative = sampled.velocities[background_index] - primary.velocity;
            require_finite_vec3(relative, "relative velocity");
            const Real speed = norm(relative);
            if (!is_finite(speed)) {
                throw Error("reaction '" + reaction.name + "' relative speed is not finite");
            }
            // 查表能量是相对运动能量 E=mu*g^2/2，不是入射粒子的实验室系动能。
            relative_energy_ev = 0.5 * reduced * speed * speed / energy_scale;
            if (!is_finite(relative_energy_ev)) {
                throw Error("reaction '" + reaction.name + "' relative energy overflowed to "
                            "infinity");
            }
            has_relative_energy = true;
            if (relative_energy_ev >= reaction.threshold_ev) {
                sigma_m2 = reaction.table.sample(relative_energy_ev, outside_domain);
                has_cross_section = true;
            } else {
                sigma_m2 = 0.0;
                has_cross_section = true;
            }
            if (!is_finite(sigma_m2)) {
                throw Error("reaction '" + reaction.name + "' sampled a non-finite cross section");
            }
            // nu=n*sigma*g：[m^-3]*[m^2]*[m/s]=[s^-1]。低于阈值时截面为零。
            actual_rate = component->density_m3 * sigma_m2 * speed;
        } else {
            StateId x_state = invalid_state;
            for (const ReactantTerm& term : reaction.reactants) {
                if (term.role == ReactantRole::Background && term.species == reaction.x_species) {
                    x_state = term.state;
                    break;
                }
            }
            const BackgroundComponent* component = find_background(
                prepared.components_view(), reaction.x_species, x_state);
            if (component == nullptr) {
                throw Error("reaction '" + reaction.name + "' is missing its x_species background");
            }
            const Real coefficient = reaction.table.sample(component->temperature_k,
                                                           outside_domain);
            if (!is_finite(coefficient)) {
                throw Error("reaction '" + reaction.name +
                            "' sampled a non-finite rate coefficient");
            }
            actual_rate = channel.density_product * coefficient;
        }
        if (!is_finite(actual_rate)) {
            throw Error("reaction '" + reaction.name +
                        "' sampled rate overflowed to infinity");
        }

        // 步骤 5：接受概率为真实频率/通道上界，必须不超过 1。
        // 超界说明假设失效，不能简单截为 1，否则统计分布会被悄悄改变。
        if (actual_rate > channel.majorant_s_inv * (1.0 + 1.0e-12)) {
            throw Error("reaction '" + reaction.name +
                        "' rate exceeds its compiled majorant; the majorant is not conservative");
        }

        ++outcome.candidates;
        CounterRng real_rng(request.seed, request.global_step, request.projectile.id,
                            event_index, slot_real);
        const bool real_event = real_rng.uniform_open() * channel.majorant_s_inv < actual_rate;

        EventRecord record;
        record.event_index = event_index;
        record.reaction = reaction.id;
        record.algorithm = reaction.algorithm;
        record.majorant_s_inv = channel.majorant_s_inv;
        record.sampled_rate_s_inv = actual_rate;
        record.background_species = channel.diagnostic_background;
        record.has_relative_energy = has_relative_energy;
        record.relative_energy_ev = relative_energy_ev;
        record.has_cross_section = has_cross_section;
        record.cross_section_m2 = sigma_m2;

        // 拒绝候选即 null collision（空碰撞）：时间已经过去，粒子状态保持不变。
        if (!real_event) {
            record.null_event = true;
            ++outcome.null_events;
            if (record_events) outcome.events.push_back(record);
            continue;
        }
        record.real_event = true;
        ++outcome.real_events;
        const auto existing = std::find_if(
            outcome.reaction_counts.begin(), outcome.reaction_counts.end(),
            [&](const auto& entry) { return entry.first == reaction.id; });
        if (existing == outcome.reaction_counts.end()) {
            outcome.reaction_counts.emplace_back(reaction.id, 1U);
        } else {
            ++existing->second;
        }

        // 步骤 6：可用动能 = 反应前动能 + 反应释放能量 - 指定辐射能量。
        // q_value 已由模型编译解释；不要再把显式能级差重复加进这里。
        // ---- construct the final state ----------------------------------
        const Real q_j = reaction.q_value_ev * energy_scale;
        const Real radiated_j = reaction.radiated_energy_ev * energy_scale;
        const Real available_kinetic_j = kinetic_before_j + q_j - radiated_j;
        if (!is_finite(available_kinetic_j)) {
            throw Error("reaction '" + reaction.name +
                        "' available kinetic energy is not finite");
        }
        const Real available_scale =
            std::max({std::fabs(kinetic_before_j), std::fabs(q_j), std::fabs(radiated_j)});
        const Real available_tolerance =
            64.0 * std::numeric_limits<Real>::epsilon() * available_scale;
        if (available_kinetic_j < -available_tolerance) {
            throw Error("reaction '" + reaction.name + "' has negative available kinetic energy");
        }
        CounterRng final_rng(request.seed, request.global_step, request.projectile.id,
                             event_index, slot_final);
        const FinalState final_state = build_final_state(
            model, reaction, primary, sampled, total_momentum,
            std::max(available_kinetic_j, 0.0), final_rng);
        if (final_state.velocities.size() != reaction.product_bodies.size()) {
            throw Error("reaction '" + reaction.name + "' produced the wrong number of bodies");
        }
        for (const Vec3 velocity : final_state.velocities) {
            require_finite_vec3(velocity, "product velocity");
        }
        if (!is_finite(final_state.unallocated_energy_j)) {
            throw Error("reaction '" + reaction.name + "' unallocated energy is not finite");
        }

        // 优先让同物种产物继承主粒子身份；否则选一个显式产物继续，或删除主粒子。
        std::size_t primary_product = reaction.product_bodies.size();
        for (std::size_t i = 0; i < reaction.product_bodies.size(); ++i) {
            if (reaction.product_bodies[i].first == reaction.projectile) {
                primary_product = i;
                break;
            }
        }
        if (primary_product == reaction.product_bodies.size()) {
            for (std::size_t i = 0; i < reaction.product_bodies.size(); ++i) {
                const Species& type = model.species.at(reaction.product_bodies[i].first);
                if (type.representation == Representation::Kinetic) {
                    primary_product = i;
                    break;
                }
            }
        }

        std::map<std::uint32_t, ReservoirDelta> reservoir;
        auto reservoir_for = [&reservoir](const SpeciesId species,
                                          const StateId state) -> ReservoirDelta& {
            ReservoirDelta& delta = reservoir[background_key(species, state)];
            delta.species = species;
            delta.state = state;
            return delta;
        };
        const Real weight = primary.weight;

        // 步骤 7：把背景收支与额外显式产物分开，所有背景收支乘模拟粒子权重。
        // 这里只返回账目，不就地更新外部背景条件。
        // Consumed background bodies.
        for (std::size_t i = 0; i < reaction.reactant_bodies.size(); ++i) {
            const SpeciesId species_id = reaction.reactant_bodies[i].first;
            if (species_id == reaction.projectile) continue;
            const Species& type = model.species.at(species_id);
            ReservoirDelta& delta = reservoir_for(species_id,
                                                  reaction.reactant_bodies[i].second);
            delta.physical_particles -= weight;
            delta.momentum_kg_m_per_s -= sampled.velocities[i] * (type.mass_kg * weight);
            delta.kinetic_energy_j -= kinetic_energy(type.mass_kg, sampled.velocities[i]) * weight;
            delta.internal_energy_j -= model.states.at(reaction.reactant_bodies[i].second).energy_ev *
                                       energy_scale * weight;
        }

        Real product_kinetic_j = 0.0;
        Vec3 product_momentum{};
        for (std::size_t i = 0; i < reaction.product_bodies.size(); ++i) {
            const SpeciesId species_id = reaction.product_bodies[i].first;
            const StateId state_id = reaction.product_bodies[i].second;
            const Species& type = model.species.at(species_id);
            const Vec3 velocity = final_state.velocities[i];
            product_kinetic_j += kinetic_energy(type.mass_kg, velocity);
            product_momentum += velocity * type.mass_kg;

            if (i == primary_product) {
                ParticleState next = primary;
                next.species = species_id;
                next.state = state_id;
                next.velocity = velocity;
                outcome.primary_after = next;
                outcome.primary_destination = species_id;
                outcome.primary_action = species_id == primary.species
                    ? PrimaryAction::Update
                    : PrimaryAction::MoveSpecies;
            } else if (type.representation == Representation::Kinetic) {
                CreatedProduct product;
                product.parent_id = primary.id;
                product.event_index = event_index;
                product.product_ordinal = static_cast<std::uint32_t>(i);
                product.species = species_id;
                product.state = state_id;
                product.position = primary.position;
                product.velocity = velocity;
                product.weight = primary.weight;
                product.birth_step = request.global_step + 1U;
                product.cell = primary.cell;
                outcome.created.push_back(product);
            } else {
                ReservoirDelta& delta = reservoir_for(species_id, state_id);
                delta.physical_particles += weight;
                delta.momentum_kg_m_per_s += velocity * (type.mass_kg * weight);
                delta.kinetic_energy_j += kinetic_energy(type.mass_kg, velocity) * weight;
                delta.internal_energy_j += model.states.at(state_id).energy_ev * energy_scale * weight;
            }
        }
        if (primary_product == reaction.product_bodies.size()) {
            outcome.primary_action = PrimaryAction::Remove;
            outcome.primary_destination = invalid_species;
        }
        require_finite_vec3(product_momentum, "product momentum");
        if (!is_finite(product_kinetic_j)) {
            throw Error("reaction '" + reaction.name + "' product kinetic energy is not finite");
        }

        // 步骤 8：守恒检查通过后累积结果。released_energy 排除已单列的能级变化，
        // 能量残差应接近零；一旦失败，整个调用抛错，不向宿主提交半成品。
        // ---- conservation ledger ----------------------------------------
        ConservationLedger ledger;
        int charge_before = 0;
        for (const ReactantTerm& term : reaction.reactants) {
            charge_before += model.species.at(term.species).charge_state *
                             static_cast<int>(term.stoichiometry);
        }
        int charge_after = 0;
        for (const ProductTerm& term : reaction.products) {
            charge_after += model.species.at(term.species).charge_state *
                            static_cast<int>(term.stoichiometry);
        }
        ledger.charge_before_c = static_cast<Real>(charge_before) * energy_scale;
        ledger.charge_after_c = static_cast<Real>(charge_after) * energy_scale;
        ledger.momentum_before_kg_m_per_s = total_momentum * weight;
        ledger.momentum_after_kg_m_per_s = product_momentum * weight;
        ledger.kinetic_before_j = kinetic_before_j * weight;
        ledger.kinetic_after_j = product_kinetic_j * weight;
        ledger.internal_before_j = reaction.internal_before_ev * energy_scale * weight;
        ledger.internal_after_j = reaction.internal_after_ev * energy_scale * weight;
        ledger.released_energy_j =
            (q_j + (reaction.internal_after_ev - reaction.internal_before_ev) * energy_scale) *
            weight;
        ledger.radiated_or_unresolved_j =
            (radiated_j + final_state.unallocated_energy_j) * weight;
        ledger.energy_residual_j = ledger.kinetic_after_j + ledger.internal_after_j +
                                   ledger.radiated_or_unresolved_j - ledger.kinetic_before_j -
                                   ledger.internal_before_j - ledger.released_energy_j;
        ledger.tolerance_j = model.options.relative_tolerance *
                             (ledger.kinetic_before_j + std::fabs(ledger.released_energy_j) +
                              ledger.radiated_or_unresolved_j + 1.0e-30);
        verify_event(model, reaction, ledger, model.options.relative_tolerance);
        append_event_ledger(outcome.ledger, ledger);
        require_finite_accumulated_ledger(outcome.ledger);

        for (auto& [key, delta] : reservoir) {
            (void)key;
            if (!is_finite(delta.physical_particles) || !is_finite(delta.kinetic_energy_j) ||
                !is_finite(delta.internal_energy_j) ||
                !is_finite(delta.momentum_kg_m_per_s.x) ||
                !is_finite(delta.momentum_kg_m_per_s.y) ||
                !is_finite(delta.momentum_kg_m_per_s.z)) {
                throw Error("reaction '" + reaction.name +
                            "' reservoir delta is not finite");
            }
            outcome.reservoir.push_back(delta);
        }
        if (record_events) outcome.events.push_back(record);

        if (outcome.primary_action == PrimaryAction::Remove ||
            (!complete_step && outcome.primary_action != PrimaryAction::Update)) break;
        // 步骤 9：用碰后的物种/能级重选通道，继续处理 remaining。
        // 即使物种相同，激发/退激后的可用反应也可能不同，不能盲用旧缓存。
        // The primary may have changed state (for example ground -> excited), so
        // the active channel set and the total majorant must be rebuilt before
        // the remaining dt is sampled. Full-step mode also rebuilds after a
        // species move; null events keep the channels unchanged.
        if (cached != nullptr && outcome.primary_after.species == cached->species &&
            outcome.primary_after.state == cached->state) {
            channels = &cached->channels;
            total_majorant = cached->total_majorant;
        } else if (cache_lookup != nullptr) {
            cached = cache_lookup(cache_context, outcome.primary_after.species,
                                  outcome.primary_after.state);
            if (cached == nullptr) throw Error("batch channel resolver returned no cache");
            channels = &cached->channels;
            total_majorant = cached->total_majorant;
        } else {
            owned_channels = build_active_channels(model, prepared, outcome.primary_after.species,
                                                    outcome.primary_after.state);
            channels = &owned_channels;
            total_majorant = total_majorant_for(*channels);
        }
    }
    if (complete_step && outcome.primary_action != PrimaryAction::Remove &&
        outcome.real_events != 0U) {
        outcome.primary_action = outcome.primary_after.species == request.projectile.species
            ? PrimaryAction::Update : PrimaryAction::MoveSpecies;
        outcome.primary_destination = outcome.primary_after.species;
    }
    return outcome;
}

} // namespace mcc
} // namespace algoplasma
