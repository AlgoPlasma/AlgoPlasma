// SPDX-License-Identifier: Apache-2.0
#include "collision_kernel.hpp"
#include <algorithm>
#include <tuple>

namespace algoplasma::dsmc {
DsmcStepper::DsmcStepper(DsmcModel model, StepOptions options)
    : model_(std::move(model)), options_(options) {
    if (!options_.max_candidates_per_cell || !options_.max_candidates_total ||
        options_.max_candidates_per_cell > 1000000000ULL ||
        options_.max_candidates_total > 1000000000000ULL ||
        !std::isfinite(options_.conservation_tolerance) || options_.conservation_tolerance <= 0 ||
        (options_.candidate_schedule != CandidateSchedule::RoundedNtc &&
         options_.candidate_schedule != CandidateSchedule::ContinuousClock)) {
        throw Error("invalid step options");
    }
}

StepReport DsmcStepper::step(std::span<CylindricalParticleState> particles,
                             const CylindricalGrid& grid, const StepContext& context,
                             DsmcWorkspace& work) const {
    if (!std::isfinite(context.dt_s) || context.dt_s < 0) {
        throw Error("dt_s must be finite and nonnegative");
    }

    // 同一网格提供单元归属和体积；排序与碰撞只修改工作快照。
    const auto cells = grid.cells();
    detail::snapshot_particles(particles, grid, model_.species().id, work.particles_);
    std::sort(work.particles_.begin(), work.particles_.end(), [](const auto& a, const auto& b) {
        return std::tie(a.cell_id, a.id) < std::tie(b.cell_id, b.id);
    });

    // 网格按 ID 顺序生成单元，快照中的 cell_id 均来自 grid.locate()。
    // offsets[c] 到 offsets[c+1] 给出单元 c 的粒子区间；空单元保留空区间。
    work.cell_offsets_.clear();
    std::size_t cursor = 0;
    for (const auto& cell : cells) {
        work.cell_offsets_.push_back(cursor);
        while (cursor < work.particles_.size() &&
               work.particles_[cursor].cell_id == cell.global_id) {
            ++cursor;
        }
    }
    work.cell_offsets_.push_back(cursor);

    StepReport report;
    report.by_cell.reserve(cells.size());

    // 各单元独立处理，逐步汇总候选数、接受数和守恒误差。
    for (std::size_t c = 0; c < cells.size(); ++c) {
        auto group =
            std::span(work.particles_)
                .subspan(work.cell_offsets_[c], work.cell_offsets_[c + 1] - work.cell_offsets_[c]);
        const auto result =
            detail::collide_cell(group, cells[c], model_, context, options_, report);
        report.candidates += result.candidates;
        report.accepted += result.accepted;
        report.rejected += result.rejected;
        report.max_relative_momentum_error =
            std::max(report.max_relative_momentum_error, result.relative_momentum_error);
        report.max_relative_energy_error =
            std::max(report.max_relative_energy_error, result.relative_energy_error);
        report.by_cell.push_back(result);
    }
    if (!finite(report.momentum_error) || !std::isfinite(report.energy_error)) {
        throw Error("weighted conservation report overflow");
    }

    // 全部单元成功后先准备每个粒子的局部速度，再统一写回；准备阶段也可以安全失败。
    detail::prepare_particle_velocities(particles, work.particles_, work.pending_velocities_);
    for (std::size_t i = 0; i < particles.size(); ++i) {
        particles[i].velocity_mps = work.pending_velocities_[i];
    }
    return report;
}
} // namespace algoplasma::dsmc
