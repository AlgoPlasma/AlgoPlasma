// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "stepper.hpp"

namespace algoplasma::dsmc::detail {
// 定位和速度变换只生成工作快照；source_index 保留原始数组中的写回位置。
void snapshot_particles(std::span<const CylindricalParticleState> particles,
                        const CylindricalGrid& grid, SpeciesId species_id,
                        std::vector<CollisionParticle>& out);

// 所有反变换与内存分配都在写回前完成，失败时原始粒子保持不变。
void prepare_particle_velocities(std::span<const CylindricalParticleState> particles,
                                 std::span<const CollisionParticle> snapshot,
                                 std::vector<CylindricalVelocity>& pending);

// 单元内核只更新工作区中的粒子快照；DsmcStepper 统一向原始粒子数组写回速度。
CellReport collide_cell(std::span<CollisionParticle> particles, const CollisionCell& cell,
                        const DsmcModel& model, const StepContext& context,
                        const StepOptions& options, StepReport& report);
} // namespace algoplasma::dsmc::detail
