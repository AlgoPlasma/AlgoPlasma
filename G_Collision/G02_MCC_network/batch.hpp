// SPDX-License-Identifier: Apache-2.0
// 整批粒子的时间推进接口。这里组织存储、并行和结果写回，
// 单个粒子的碰撞物理由 engine.hpp 中的 MccEngine 负责。
// 初读可先看 StepOptions、StepReport、MccStepper，再看适配器和工作区。
#pragma once

#include "engine.hpp"

#include <cstddef>
#include <cstdint>
#include <exception>
#include <memory>
#include <map>
#include <vector>

namespace algoplasma::mcc {

// cell 是网格编号；UINT32_MAX 表示没有局部背景时使用的统一背景。
struct CellBackground {
    // UINT32_MAX supplies a spatially uniform fallback.
    std::uint32_t cell{0};
    BackgroundComponent component;
};

// index 是当前容器下标，不是永久 id；压缩容器后下标可能变化。
struct ParticleChange {
    std::size_t index{0};
    PrimaryAction action{PrimaryAction::None};
    ParticleState after;
};

// The host owns its particle storage. prepare_commit may allocate and fail, but
// must leave the visible particle state unchanged. commit must not fail.
// Its change/product inputs remain alive and unchanged through commit().
// begin_step refreshes adapter indices after external host mutations and must
// also leave visible particle state unchanged.
// 适配器连接不同存储方式。prepare_commit 可分配和报错，commit 必须不抛异常。
class ParticleAdapter {
public:
    virtual ~ParticleAdapter() = default;
    virtual void begin_step() {}
    [[nodiscard]] virtual std::size_t size() const = 0;
    [[nodiscard]] virtual bool alive(std::size_t index) const = 0;
    [[nodiscard]] virtual ParticleState particle(std::size_t index) const = 0;
    [[nodiscard]] virtual std::uint64_t next_id_hint() const noexcept = 0;
    virtual void prepare_commit(const std::vector<ParticleChange>& changes,
                                const std::vector<ParticleState>& created,
                                std::uint64_t next_id) = 0;
    virtual void commit() noexcept = 0;
};

// A ready-to-use contiguous adapter. A PIC with its own container implements
// ParticleAdapter once; its time loop still makes one step() call.
class VectorParticleAdapter final : public ParticleAdapter {
public:
    explicit VectorParticleAdapter(std::vector<ParticleState>& particles,
                                   std::uint64_t next_id_hint = 0)
        : particles_(particles), next_id_(next_id_hint) {}
    [[nodiscard]] std::size_t size() const override { return particles_.size(); }
    [[nodiscard]] bool alive(std::size_t index) const override { return index < particles_.size(); }
    [[nodiscard]] ParticleState particle(std::size_t index) const override {
        return particles_.at(index);
    }
    [[nodiscard]] std::uint64_t next_id_hint() const noexcept override { return next_id_; }
    void prepare_commit(const std::vector<ParticleChange>& changes,
                        const std::vector<ParticleState>& created,
                        std::uint64_t next_id) override;
    void commit() noexcept override {
        if (staged_updates_only_) {
            for (const ParticleChange& change : *pending_updates_) {
                particles_[change.index] = change.after;
            }
        } else if (!staged_noop_) {
            particles_.swap(staged_);
        }
        pending_updates_ = nullptr;
        next_id_ = staged_next_id_;
    }
    [[nodiscard]] std::uint64_t next_id() const noexcept { return next_id_; }

private:
    std::vector<ParticleState>& particles_;
    std::vector<ParticleState> staged_;
    std::uint64_t next_id_{0};
    std::uint64_t staged_next_id_{0};
    bool staged_noop_{false};
    bool staged_updates_only_{false};
    const std::vector<ParticleChange>* pending_updates_{nullptr};
};

// SoA 将各属性分别存成数组；vx[i]、vy[i] 属于同一粒子，各数组长度须一致。
class ParticleSoA {
public:
    [[nodiscard]] std::size_t size() const noexcept { return id.size(); }
    void reserve(std::size_t capacity);
    void push(const ParticleState& value);
    [[nodiscard]] ParticleState get(SpeciesId species, std::size_t index) const;
    void set(std::size_t index, const ParticleState& value) noexcept;
    void mark_dead(std::size_t index) noexcept { alive[index] = 0U; }
    [[nodiscard]] bool is_alive(std::size_t index) const noexcept { return alive[index] != 0U; }
    void compact() noexcept;

private:
    std::vector<Real> x, y, z, vx, vy, vz, weight;
    std::vector<std::uint64_t> id, birth_step;
    std::vector<StateId> state;
    std::vector<std::uint32_t> cell;
    std::vector<std::uint8_t> alive;
};

class ParticleBank {
public:
    explicit ParticleBank(const CompiledModel& model);
    void push(const ParticleState& particle);
    [[nodiscard]] const ParticleSoA& at(SpeciesId species) const { return blocks_.at(species); }
    [[nodiscard]] std::size_t total_size() const noexcept;
    [[nodiscard]] std::uint64_t next_id() const noexcept { return next_id_; }

private:
    std::map<SpeciesId, ParticleSoA> blocks_;
    std::uint64_t next_id_{0};
    friend class SoaParticleAdapter;
};

class SoaParticleAdapter final : public ParticleAdapter {
public:
    explicit SoaParticleAdapter(ParticleBank& bank);
    void begin_step() override;
    [[nodiscard]] std::size_t size() const override { return slots_.size(); }
    [[nodiscard]] bool alive(std::size_t index) const override;
    [[nodiscard]] ParticleState particle(std::size_t index) const override;
    [[nodiscard]] std::uint64_t next_id_hint() const noexcept override { return bank_.next_id_; }
    void prepare_commit(const std::vector<ParticleChange>& changes,
                        const std::vector<ParticleState>& created,
                        std::uint64_t next_id) override;
    void commit() noexcept override;

private:
    struct Slot { SpeciesId species; std::size_t index; };
    ParticleBank& bank_;
    std::vector<Slot> slots_;
    std::vector<Slot> next_slots_;
    std::vector<ParticleChange> changes_;
    std::vector<ParticleState> created_;
    std::uint64_t staged_next_id_{0};
    bool staged_noop_{false};
    bool staged_updates_only_{false};
    const std::vector<ParticleChange>* pending_updates_{nullptr};
};

enum class CpuBackend : std::uint8_t { Auto, Serial, OpenMp };

// 执行选项：Auto 按粒子规模选择串行或 OpenMP。
struct StepOptions {
    CpuBackend backend{CpuBackend::Auto};
    unsigned threads{0}; // 0 uses the OpenMP runtime choice.
    std::size_t min_parallel_particles{4096};
    std::uint32_t max_candidates_per_particle{1000000};
    bool record_events{false};
    bool exact_pruning{true};
    ChannelSampler sampler{ChannelSampler::Prefix};
};

struct CellReservoirDelta {
    std::uint32_t cell{0};
    ReservoirDelta delta;
};

struct ParticleEvent {
    std::uint64_t particle_id{0};
    std::uint32_t cell{0};
    EventRecord event;
};

// 本次统计：候选次数 = 真碰撞次数 + 空碰撞次数；空碰撞不改变物理状态。
struct StepReport {
    std::uint64_t particles_visited{0};
    std::uint64_t candidates{0};
    std::uint64_t real_events{0};
    std::uint64_t null_events{0};
    std::uint64_t created_particles{0};
    std::vector<std::pair<ReactionId, std::uint64_t>> by_reaction;
    std::vector<CellReservoirDelta> reservoir;
    std::vector<ParticleEvent> events;
    ConservationLedger ledger;
    Real preparation_seconds{0};
    Real sampling_seconds{0};
    Real reduction_seconds{0};
    Real commit_seconds{0};
    Real total_seconds{0};
};

// 工作区复用临时数组和缓存；同一时刻只能容纳一个尚未完成的时间步。
class MccWorkspace {
public:
    MccWorkspace();
    ~MccWorkspace();
    MccWorkspace(MccWorkspace&&) = delete;
    MccWorkspace& operator=(MccWorkspace&&) = delete;
    MccWorkspace(const MccWorkspace&) = delete;
    MccWorkspace& operator=(const MccWorkspace&) = delete;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
    friend class MccStepper;
    friend class PreparedMccStep;
};

// 父粒子 id、事件序号和产物序号构成出生键，用于稳定地分配新编号。
struct BirthKey {
    std::uint64_t parent_id{0};
    std::uint32_t event_index{0};
    std::uint32_t product_ordinal{0};
};

// Visible particles stay unchanged until commit(). A prepared step keeps its
// workspace occupied, including while an MPI caller agrees on child IDs.
class PreparedMccStep {
public:
    PreparedMccStep() = default;
    ~PreparedMccStep();
    PreparedMccStep(PreparedMccStep&& other) noexcept;
    PreparedMccStep& operator=(PreparedMccStep&& other) noexcept;
    PreparedMccStep(const PreparedMccStep&) = delete;
    PreparedMccStep& operator=(const PreparedMccStep&) = delete;

    [[nodiscard]] bool valid() const noexcept { return workspace_ != nullptr; }
    [[nodiscard]] const StepReport& report() const;
    [[nodiscard]] std::uint64_t largest_id() const;
    [[nodiscard]] std::vector<BirthKey> birth_keys() const;
    void prepare_commit(ParticleAdapter& particles,
                        const std::vector<std::uint64_t>& child_ids,
                        std::uint64_t next_id);
    void commit(ParticleAdapter& particles) noexcept;
    [[nodiscard]] StepReport take_report();

private:
    explicit PreparedMccStep(MccWorkspace& workspace) : workspace_(&workspace) {}
    MccWorkspace* workspace_{nullptr};
    bool ready_{false};
    bool committed_{false};
    friend class MccStepper;
};

// 整批推进 dt_s 秒；global_step 是步数，seed 是随机种子。
// 一个物理时间步只调用一个 step 重载；带工作区的重载适合循环复用。
class MccStepper {
public:
    explicit MccStepper(MccEngine engine, StepOptions options = {})
        : engine_(std::move(engine)), options_(options) {}

    [[nodiscard]] const MccEngine& engine() const noexcept { return engine_; }
    [[nodiscard]] StepReport step(ParticleAdapter& particles,
                                  const std::vector<CellBackground>& background,
                                  Real dt_s, std::uint64_t global_step,
                                  std::uint64_t seed) const;
    [[nodiscard]] StepReport step(ParticleAdapter& particles,
                                  const std::vector<CellBackground>& background,
                                  Real dt_s, std::uint64_t global_step,
                                  std::uint64_t seed, MccWorkspace& workspace) const;
    [[nodiscard]] PreparedMccStep prepare_step(
        ParticleAdapter& particles, const std::vector<CellBackground>& background,
        Real dt_s, std::uint64_t global_step, std::uint64_t seed,
        MccWorkspace& workspace) const;

private:
    MccEngine engine_;
    StepOptions options_;
};

} // namespace algoplasma::mcc
