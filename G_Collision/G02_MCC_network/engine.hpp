// SPDX-License-Identifier: Apache-2.0
//
// G02_MCC_network engine.
//
// MccEngine::collide() samples one explicit particle step against one or two
// background reservoir components and returns an immutable StepOutcome. The
// caller (host PIC loop) owns the particle store and decides how to commit the
// outcome atomically.
// 阅读顺序：输入 ParticleState / CollisionRequest → 输出 StepOutcome → MccEngine 接口。
// 本文件定义“传入什么、返回什么”；抽样流程在 fun_G02_mcc_engine.cpp。
// MCC（Monte Carlo Collision）用随机抽样再现大量粒子的统计碰撞规律。
#pragma once

#include "common.hpp"
#include "compile.hpp"
#include "model.hpp"

#include <cstdint>
#include <filesystem>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

namespace algoplasma {
namespace mcc {

// 1. 输入：一个显式跟踪的模拟粒子。位置用 m，速度用 m/s；weight 是代表的真实粒子数。
// species 与 state 必须是模型中相互匹配的有效编号；id 用于可重放的随机抽样。
struct ParticleState {
    SpeciesId species{invalid_species};
    StateId state{invalid_state};
    Vec3 position{};
    Vec3 velocity{};
    Real weight{1.0};
    std::uint64_t id{0};
    std::uint64_t birth_step{0};
    std::uint32_t cell{0};
};

// 背景粒子不逐个存储，用密度 n [m^-3]、温度 T [K]、平均漂移速度描述。
// state=invalid_state 表示按物种汇总的背景，不能照搬为 projectile 的状态。
struct BackgroundComponent {
    SpeciesId species{invalid_species};
    Real density_m3{};
    Real temperature_k{300.0};
    Vec3 drift_m_per_s{};
    // An invalid state preserves the v1 species-aggregated background contract.
    StateId state{invalid_state};
};

// 一个 channel（通道）就是当前入射物种/能级可走的一条反应。
// majorant 是该通道碰撞频率的保守上界 [s^-1]，用来先生成候选事件。
struct PreparedChannel {
    std::size_t index{0};
    Real majorant_s_inv{};
    Real density_product{};
    SpeciesId diagnostic_background{invalid_species};
};

// Prefix 用累计权重查找通道；Alias 预建别名表，两者抽样的目标概率相同。
enum class ChannelSampler : std::uint8_t { Prefix, Alias };
using BackgroundIndex = std::unordered_map<std::uint32_t, const BackgroundComponent*>;
using ChannelCacheLookup = const struct CachedChannels* (*)(void*, SpeciesId, StateId);

// 同一背景及入射物种/能级下复用的抽样表；背景条件改变后不能沿用旧表。
struct CachedChannels {
    SpeciesId species{invalid_species};
    StateId state{invalid_state};
    std::vector<PreparedChannel> channels;
    std::vector<Real> cumulative_majorants;
    std::vector<Real> alias_probability;
    std::vector<std::size_t> alias_index;
    Real total_majorant{};
};

// 一次调用的完整条件。projectile 是调用开始时的入射粒子；dt_s 为时间步 [s]。
// background_view / cached_channels 为借用指针，其数据在同步调用结束前必须有效。
struct CollisionRequest {
    ParticleState projectile;
    std::vector<BackgroundComponent> background;
    Real dt_s{};
    std::uint64_t global_step{0};
    std::uint64_t seed{0};
    // 0 selects CompiledModel::options.max_events_per_step (default 64).
    std::uint32_t max_events_per_step{0};
    // Borrowed for a synchronous batch call; when absent, background is used.
    const std::vector<BackgroundComponent>* background_view{nullptr};
    bool exact_pruning{false};
    const CachedChannels* cached_channels{nullptr}; // synchronous batch call only
};

// 2. 输出：primary 是沿当前粒子身份继续跟踪的主粒子，可能变物种或被移除。
// None 不改动；Update 更新状态；Remove 删除；MoveSpecies 移入另一个物种的存储区。
enum class PrimaryAction : std::uint8_t {
    None = 0,
    Update = 1,
    Remove = 2,
    MoveSpecies = 3
};

[[nodiscard]] const char* to_string(PrimaryAction value) noexcept;

// 额外生成的显式粒子描述。全局唯一新编号由宿主/批量提交层分配，
// parent_id、event_index、product_ordinal 用来标识出生来源。
struct CreatedProduct {
    std::uint64_t parent_id{0};
    std::uint32_t event_index{0};
    std::uint32_t product_ordinal{0};
    SpeciesId species{invalid_species};
    StateId state{invalid_state};
    Vec3 position{};
    Vec3 velocity{};
    Real weight{1.0};
    std::uint64_t birth_step{0};
    std::uint32_t cell{0};
};

// 背景库的收支：消耗为负，生成为正；已乘粒子权重。
// 返回这些量供宿主更新背景，本引擎不会自行改变背景密度或温度。
struct ReservoirDelta {
    SpeciesId species{invalid_species};
    StateId state{invalid_state};
    Real physical_particles{};
    Vec3 momentum_kg_m_per_s{};
    Real kinetic_energy_j{};
    Real internal_energy_j{};
};

// 候选事件记录。null_event（空碰撞）只消耗抽样时间，不改变粒子速度。
// has_* 为 false 时，相应诊断数值不应解释为已计算出的物理量。
struct EventRecord {
    std::uint32_t event_index{0};
    ReactionId reaction{invalid_reaction};
    CollisionAlgorithm algorithm{CollisionAlgorithm::C02Elastic};
    bool real_event{false};
    bool null_event{false};
    Real majorant_s_inv{};
    Real sampled_rate_s_inv{};
    SpeciesId background_species{invalid_species};
    bool has_relative_energy{false};
    Real relative_energy_ev{};
    bool has_cross_section{false};
    Real cross_section_m2{};
};

// 守恒账本同时计入显式粒子、背景和辐射/未解析能量，不能只比较主粒子动能。
// 动量与能量项已乘权重；电荷项记录每次反应式的电荷平衡 [C]。
struct ConservationLedger {
    Real charge_before_c{};
    Real charge_after_c{};
    Vec3 momentum_before_kg_m_per_s{};
    Vec3 momentum_after_kg_m_per_s{};
    Real kinetic_before_j{};
    Real kinetic_after_j{};
    Real internal_before_j{};
    Real internal_after_j{};
    // Energy released by internal/chemical rearrangement, excluding the part
    // already accounted for by explicit state energies.
    Real released_energy_j{};
    Real radiated_or_unresolved_j{};
    Real energy_residual_j{};
    Real tolerance_j{};
};

// 汇总本次调用的变化，宿主检查成功后再提交到自己的粒子数组。
// candidates = real_events + null_events；候选次数不等于真实碰撞次数。
struct StepOutcome {
    PrimaryAction primary_action{PrimaryAction::None};
    ParticleState primary_after{};
    SpeciesId primary_destination{invalid_species};
    std::vector<CreatedProduct> created;
    std::vector<ReservoirDelta> reservoir;
    std::vector<EventRecord> events;
    std::vector<std::pair<ReactionId, std::uint32_t>> reaction_counts;
    ConservationLedger ledger;
    std::uint32_t candidates{0};
    std::uint32_t real_events{0};
    std::uint32_t null_events{0};
    bool event_limit_reached{false};
};

// 单通道诊断；rate_defined=false 表示此处未计算真实频率，不表示频率为零。
struct ChannelDiagnostics {
    ReactionId reaction{invalid_reaction};
    CollisionAlgorithm algorithm{CollisionAlgorithm::C02Elastic};
    RateKind rate_kind{RateKind::CrossSection};
    bool rate_defined{false};
    Real rate_s_inv{};
    Real majorant_s_inv{};
};

// 3. 计算入口：持有只读编译模型，产生变化描述，不负责位置推进/电磁场求解。
class MccEngine {
public:
    // 已有 CompiledModel 时直接构造；load 则依次读取 CSV、校验并编译模型。
    explicit MccEngine(CompiledModel model);

    [[nodiscard]] static MccEngine load(const std::filesystem::path& package_dir,
                                        CompileOptions options = {});

    [[nodiscard]] const CompiledModel& model() const noexcept { return *model_; }

    // 把 CSV 中的名字换为运行时编号；初始化时查一次，循环里复用编号。
    [[nodiscard]] SpeciesId species_id(const std::string& name) const;
    [[nodiscard]] StateId state_id(SpeciesId species, const std::string& label) const;
    [[nodiscard]] std::string species_name(SpeciesId species) const;

    // collide 为受限步进：达到候选上限会标记 event_limit_reached；
    // 主粒子变物种时也可能提前结束。需要完整 dt 时使用 collide_full / MccStepper。
    // Sample one step. Throws Error on any invalid input, missing background,
    // domain violation, majorant violation or failed conservation check. On
    // success the input request is never modified and the returned StepOutcome
    // is the only artifact.
    [[nodiscard]] StepOutcome collide(const CollisionRequest& request) const;

    // Complete the requested dt, including after a primary species change.
    // Exceeding max_candidates is a hard error rather than a truncated step.
    [[nodiscard]] StepOutcome collide_full(const CollisionRequest& request,
                                           std::uint32_t max_candidates = 1000000,
                                           bool record_events = false) const;

    // Per-channel majorants and, for temperature-based rate coefficients, the
    // exact instantaneous rate. Useful for host diagnostics and tests.
    [[nodiscard]] std::vector<ChannelDiagnostics> evaluate_channels(
        const CollisionRequest& request) const;

private:
    // 批量层使用的缓存与统一抽样内核；普通调用者使用上面的公开入口即可。
    [[nodiscard]] CachedChannels prepare_channels(
        const std::vector<BackgroundComponent>& background,
        SpeciesId species, StateId state, bool exact_pruning,
        ChannelSampler sampler) const;
    [[nodiscard]] StepOutcome collide_impl(const CollisionRequest& request,
                                           bool complete_step,
                                           std::uint32_t max_candidates,
                                           bool record_events,
                                           const BackgroundIndex* background_index = nullptr,
                                           ChannelCacheLookup cache_lookup = nullptr,
                                           void* cache_context = nullptr) const;
    [[nodiscard]] BackgroundIndex index_background(
        const std::vector<BackgroundComponent>& background) const;
    [[nodiscard]] StepOutcome collide_full_batch(
        const CollisionRequest& request, const BackgroundIndex& background_index,
        ChannelCacheLookup lookup, void* lookup_context,
        std::uint32_t max_candidates, bool record_events) const;
    std::shared_ptr<const CompiledModel> model_;
    friend class MccStepper;
};

} // namespace mcc
} // namespace algoplasma
