// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "cylindrical.hpp"

namespace algoplasma::dsmc {
// 调用程序保存柱坐标位置和局部物理速度；step() 只更新速度。
struct CylindricalParticleState {
    ParticleId id{};
    SpeciesId species_id{};
    CylindricalPosition position{};
    CylindricalVelocity velocity_mps{};
};
} // namespace algoplasma::dsmc
