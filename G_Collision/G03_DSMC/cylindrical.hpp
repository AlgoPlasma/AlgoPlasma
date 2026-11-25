// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "common.hpp"
#include <optional>
#include <span>
#include <vector>

namespace algoplasma::dsmc {
// 网格生成的碰撞单元：编号唯一，volume_m3 为柱坐标体积积分得到的真实体积。
struct CollisionCell {
    CellId global_id{};
    Real volume_m3{};
};

struct CylindricalPosition {
    Real r_m{}, theta_rad{}, z_m{};
};

// vtheta 是物理切向速度 r*dtheta/dt，单位 m/s，不是角速度。
struct CylindricalVelocity {
    Real vr_mps{}, vtheta_mps{}, vz_mps{};
};

Vec3 to_cartesian_velocity(CylindricalVelocity velocity, Real theta_rad);
CylindricalVelocity to_cylindrical_velocity(Vec3 velocity, Real theta_rad);

enum class AngularBoundary { nonperiodic, periodic };

// 固定拓扑、非均匀、真正三维的 r/theta/z 网格；不处理输运或物理边界条件。
// 每个轴至少两个严格递增的有限面坐标，r >= 0，角跨度不超过完整一圈。
// periodic 明确要求角跨度为 2*pi（允许浮点舍入误差），按存储的跨度包裹；
// nonperiodic 不包裹任何角度。
class CylindricalGrid {
public:
    CylindricalGrid(std::vector<Real> radial_faces_m, std::vector<Real> angular_faces_rad,
                    std::vector<Real> axial_faces_m, AngularBoundary angular_boundary,
                    CellId first_cell_id = 0);

    std::span<const CollisionCell> cells() const noexcept {
        return cells_;
    }

    // ID = first_cell_id + ((ir * Ntheta) + itheta) * Nz + iz。
    // 区间半开：内部面归右侧，非周期最大面不属于网格。域外返回 nullopt；
    // 非有限坐标或负半径抛出 Error。完整周期的最大角面归首角单元。
    // r=0 时仍使用传入 theta 定位并定义局部基底，绝不自行重设为零。
    std::optional<CellId> locate(CylindricalPosition position) const;

private:
    std::vector<Real> radial_faces_m_, angular_faces_rad_, axial_faces_m_;
    AngularBoundary angular_boundary_;
    CellId first_cell_id_;
    std::vector<CollisionCell> cells_;
};
} // namespace algoplasma::dsmc
