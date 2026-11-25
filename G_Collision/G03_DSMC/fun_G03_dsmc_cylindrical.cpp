// SPDX-License-Identifier: Apache-2.0
#include "cylindrical.hpp"
#include <algorithm>
#include <utility>

namespace algoplasma::dsmc {
namespace {
void validate_faces(std::span<const Real> faces, const char* name) {
    if (faces.size() < 2) {
        throw Error(std::string(name) + " needs at least two faces");
    }
    for (std::size_t i = 0; i < faces.size(); ++i) {
        if (!std::isfinite(faces[i]) || (i && !(faces[i] > faces[i - 1]))) {
            throw Error(std::string(name) + " faces must be finite and strictly increasing");
        }
    }
}

std::size_t checked_product(std::size_t a, std::size_t b) {
    if (a > std::numeric_limits<std::size_t>::max() / b) {
        throw Error("cylindrical cell count overflows size_t");
    }
    return a * b;
}

std::optional<std::size_t> interval(std::span<const Real> faces, Real coordinate) {
    if (coordinate < faces.front() || coordinate >= faces.back()) {
        return std::nullopt;
    }
    return static_cast<std::size_t>(std::upper_bound(faces.begin(), faces.end(), coordinate) -
                                    faces.begin() - 1);
}

void validate_velocity(Vec3 velocity, Real theta) {
    if (!finite(velocity) || !std::isfinite(theta)) {
        throw Error("velocity and its cylindrical basis angle must be finite");
    }
}
} // namespace

Vec3 to_cartesian_velocity(CylindricalVelocity velocity, Real theta_rad) {
    validate_velocity({velocity.vr_mps, velocity.vtheta_mps, velocity.vz_mps}, theta_rad);
    const auto c = std::cos(theta_rad), s = std::sin(theta_rad);
    const Vec3 result{velocity.vr_mps * c - velocity.vtheta_mps * s,
                      velocity.vr_mps * s + velocity.vtheta_mps * c, velocity.vz_mps};
    if (!finite(result)) {
        throw Error("Cartesian velocity cannot be represented by Real");
    }
    return result;
}

CylindricalVelocity to_cylindrical_velocity(Vec3 velocity, Real theta_rad) {
    validate_velocity(velocity, theta_rad);
    const auto c = std::cos(theta_rad), s = std::sin(theta_rad);
    const CylindricalVelocity result{velocity.x * c + velocity.y * s,
                                     -velocity.x * s + velocity.y * c, velocity.z};
    validate_velocity({result.vr_mps, result.vtheta_mps, result.vz_mps}, theta_rad);
    return result;
}

CylindricalGrid::CylindricalGrid(std::vector<Real> radial_faces_m,
                                 std::vector<Real> angular_faces_rad,
                                 std::vector<Real> axial_faces_m, AngularBoundary angular_boundary,
                                 CellId first_cell_id)
    : radial_faces_m_(std::move(radial_faces_m)), angular_faces_rad_(std::move(angular_faces_rad)),
      axial_faces_m_(std::move(axial_faces_m)), angular_boundary_(angular_boundary),
      first_cell_id_(first_cell_id) {
    validate_faces(radial_faces_m_, "radial");
    validate_faces(angular_faces_rad_, "angular");
    validate_faces(axial_faces_m_, "axial");
    if (radial_faces_m_.front() < 0) {
        throw Error("radial faces must be nonnegative");
    }
    if (angular_boundary_ != AngularBoundary::nonperiodic &&
        angular_boundary_ != AngularBoundary::periodic) {
        throw Error("unknown angular boundary mode");
    }
    const long double span =
        static_cast<long double>(angular_faces_rad_.back()) - angular_faces_rad_.front();
    const long double full_turn = 2 * static_cast<long double>(pi);
    const long double tolerance = 16 * std::numeric_limits<Real>::epsilon() * full_turn;
    if (span > full_turn + tolerance || (angular_boundary_ == AngularBoundary::periodic &&
                                         std::abs(span - full_turn) > tolerance)) {
        throw Error("angular span must be <= 2*pi; periodic grids require a full 2*pi span");
    }

    const auto nr = radial_faces_m_.size() - 1, nt = angular_faces_rad_.size() - 1,
               nz = axial_faces_m_.size() - 1;
    const auto count = checked_product(checked_product(nr, nt), nz);
    if (count > cells_.max_size() ||
        count - 1 > std::numeric_limits<CellId>::max() - first_cell_id_) {
        throw Error("cylindrical cell count or ID range cannot be represented");
    }
    cells_.reserve(count);
    for (std::size_t ir = 0; ir < nr; ++ir) {
        const long double r0 = radial_faces_m_[ir], r1 = radial_faces_m_[ir + 1];
        // 差的乘积避免 r1^2-r0^2 的消减，也避免在 Real 中过早溢出。
        const long double radial_area = (r1 - r0) * (r1 + r0) / 2;
        for (std::size_t it = 0; it < nt; ++it) {
            const long double dtheta =
                static_cast<long double>(angular_faces_rad_[it + 1]) - angular_faces_rad_[it];
            for (std::size_t iz = 0; iz < nz; ++iz) {
                const long double dz =
                    static_cast<long double>(axial_faces_m_[iz + 1]) - axial_faces_m_[iz];
                const long double exact_volume = radial_area * dtheta * dz;
                if (!(exact_volume > 0) || !std::isfinite(exact_volume) ||
                    exact_volume > std::numeric_limits<Real>::max()) {
                    throw Error("cylindrical cell volume must be finite, positive and "
                                "representable");
                }
                const Real volume = static_cast<Real>(exact_volume);
                if (!(volume > 0)) {
                    throw Error("cylindrical cell volume must be finite, positive and "
                                "representable");
                }
                cells_.push_back({first_cell_id_ + static_cast<CellId>(cells_.size()), volume});
            }
        }
    }
}

std::optional<CellId> CylindricalGrid::locate(CylindricalPosition position) const {
    if (!std::isfinite(position.r_m) || !std::isfinite(position.theta_rad) ||
        !std::isfinite(position.z_m) || position.r_m < 0) {
        throw Error("cylindrical position must be finite with nonnegative radius");
    }
    const auto ir = interval(radial_faces_m_, position.r_m);
    const auto iz = interval(axial_faces_m_, position.z_m);
    if (!ir || !iz) {
        return std::nullopt;
    }
    const auto theta = position.theta_rad;
    auto it = interval(angular_faces_rad_, theta);
    if (angular_boundary_ == AngularBoundary::periodic &&
        (theta < angular_faces_rad_.front() || theta >= angular_faces_rad_.back())) {
        const long double start = angular_faces_rad_.front();
        const long double period = static_cast<long double>(angular_faces_rad_.back()) - start;
        long double offset = std::fmod(static_cast<long double>(theta) - start, period);
        if (offset < 0) {
            offset += period;
            // 负的极小偏移仍在末单元；加上一整圈舍入到 period 时不能变成首单元。
            if (offset >= period) {
                offset = std::nextafter(period, 0.0L);
            }
        }
        // 直接比较相对面坐标，避免重新转成 Real 时将接缝附近的点舍入到错误单元。
        const auto upper =
            std::upper_bound(angular_faces_rad_.begin(), angular_faces_rad_.end(), offset,
                             [start](long double value, Real face) {
                                 return value < static_cast<long double>(face) - start;
                             });
        it = static_cast<std::size_t>(upper - angular_faces_rad_.begin() - 1);
    }
    if (!it) {
        return std::nullopt;
    }
    const auto index =
        (*ir * (angular_faces_rad_.size() - 1) + *it) * (axial_faces_m_.size() - 1) + *iz;
    return first_cell_id_ + static_cast<CellId>(index);
}
} // namespace algoplasma::dsmc
