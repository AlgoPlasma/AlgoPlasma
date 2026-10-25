// SPDX-License-Identifier: Apache-2.0
#include "scattering.hpp"
#include <algorithm>

namespace algoplasma::dsmc {
namespace {
Vec3 scatter(Vec3 incoming, Real inverse_alpha, RandomStream& rng) {
    const Real g = norm(incoming);
    if (!std::isfinite(g)) {
        throw Error("nonfinite incoming relative speed");
    }
    if (g == 0) {
        return {};
    }

    // VSS 逆变换抽样：cos(chi) = 2 * R^(1/alpha) - 1；alpha = 1 时各向同性。
    const Real mu = 2 * std::pow(rng.uniform(), inverse_alpha) - 1;
    const Real azimuth = 2 * pi * rng.uniform();

    // 以入射方向为轴建立局部正交基；辅助轴避开与入射方向近似平行的情况。
    const Vec3 axis = incoming / g;
    const Vec3 helper = std::abs(axis.x) < 0.8 ? Vec3{1, 0, 0} : Vec3{0, 1, 0};
    const Vec3 perpendicular = cross(axis, helper);
    const Vec3 e1 = perpendicular / norm(perpendicular);
    const Vec3 e2 = cross(axis, e1);

    // 只改变相对速度的方向；max 防止舍入使根号内出现微小负数。
    const Real sine = std::sqrt(std::max(0.0, (1 - mu) * (1 + mu)));
    return (axis * mu + (e1 * std::cos(azimuth) + e2 * std::sin(azimuth)) * sine) * g;
}
} // namespace

Vec3 IsotropicScattering::sample(Vec3 incoming, RandomStream& rng) const {
    return scatter(incoming, 1.0, rng);
}

VssScattering::VssScattering(Real alpha) : inverse_alpha_(1 / alpha) {
    if (!std::isfinite(alpha) || alpha < 1) {
        throw Error("alpha must be finite and >= 1");
    }
}

Vec3 VssScattering::sample(Vec3 incoming, RandomStream& rng) const {
    return scatter(incoming, inverse_alpha_, rng);
}
} // namespace algoplasma::dsmc
