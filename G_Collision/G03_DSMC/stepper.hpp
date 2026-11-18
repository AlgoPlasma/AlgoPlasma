// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "model.hpp"
#include "particles.hpp"
#include <array>
#include <optional>

namespace algoplasma::dsmc {
// 同一物理步须保持这些标识稳定，以便重放相同的随机碰撞过程。
struct StepContext {
    Real dt_s{};
    std::uint64_t global_step{}, seed{};
    std::uint32_t substep{};
};

// 只改变候选的时间调度；两者共用选对、接受判定、散射和整步提交。
enum class CandidateSchedule { RoundedNtc, ContinuousClock };

struct StepOptions {
    // 候选数预算限制异常输入引起的计算量；日志上限只限制记录，不截断碰撞计算。
    std::uint64_t max_candidates_per_cell{1000000}, max_candidates_total{10000000};
    bool record_events{false};
    std::size_t max_event_records{10000};
    Real conservation_tolerance{1e-8};
    // 连续时钟仅改变固定成员弹性体系的候选时刻，不支持在 step() 中增删粒子。
    CandidateSchedule candidate_schedule{CandidateSchedule::RoundedNtc};
};

struct CellReport {
    CellId cell_id{};
    std::uint64_t candidates{}, accepted{}, rejected{};
    Real majorant_m3_per_s{}, relative_momentum_error{}, relative_energy_error{};
};

struct EventRecord {
    CellId cell_id{};
    ParticleId first_id{}, second_id{};
    std::uint64_t candidate_index{};
    std::array<Vec3, 2> before, after;
    // 连续时钟下相对于本碰撞子步起点的浮点近似时间（s）；NTC 不赋予事件时间。
    std::optional<Real> time_offset_s{};
};

struct StepReport {
    std::uint64_t candidates{}, accepted{}, rejected{};
    std::vector<CellReport> by_cell;
    std::vector<EventRecord> events;
    Vec3 momentum_error{}; // 含粒子权重的实验室系动量残差，单位 kg m/s。
    Real energy_error{};   // 含粒子权重的实验室系动能残差，单位 J。
    Real max_relative_momentum_error{}, max_relative_energy_error{};
    bool events_truncated{false};
};

namespace detail {
// 碰撞工作快照使用共同 xyz 基底；原速度用于识别无变化样本，原下标用于直接写回。
struct CollisionParticle {
    ParticleId id{};
    CellId cell_id{};
    Vec3 velocity_mps{}, initial_velocity_mps{};
    std::size_t source_index{};
};
} // namespace detail

// 可复用的临时内存，不保存需要检查点恢复的随机历史。
// 同一工作区或同一原始粒子存储不能同时参与多个 step() 调用。
class DsmcWorkspace {
private:
    std::vector<detail::CollisionParticle> particles_;
    std::vector<std::size_t> cell_offsets_;
    std::vector<CylindricalVelocity> pending_velocities_;
    friend class DsmcStepper;
};

class DsmcStepper {
public:
    explicit DsmcStepper(DsmcModel model, StepOptions options = {});

    const DsmcModel& model() const noexcept {
        return model_;
    }

    // 在快照中完成所有单元的碰撞与检查，再统一提交；失败时保留原始粒子速度。
    // 调用期间粒子存储和网格保持有效且不被其他代码修改；定位与体积取自同一网格。
    StepReport step(std::span<CylindricalParticleState> particles, const CylindricalGrid& grid,
                    const StepContext& context, DsmcWorkspace& workspace) const;

private:
    DsmcModel model_;
    StepOptions options_;
};
} // namespace algoplasma::dsmc
