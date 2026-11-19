// SPDX-License-Identifier: Apache-2.0
#include "rate.hpp"

namespace algoplasma::dsmc {
HardSphereRate::HardSphereRate(Real diameter) : cross_section_m2_(pi * diameter * diameter) {
    detail::require_positive(diameter, "diameter");
    detail::require_positive(cross_section_m2_, "cross section");
}

Real HardSphereRate::kernel(Real g) const {
    if (!std::isfinite(g) || g < 0) {
        throw Error("invalid relative speed");
    }
    const Real q = cross_section_m2_ * g;
    if (!std::isfinite(q)) {
        throw Error("nonfinite HS kernel");
    }
    return q;
}

VhsRate::VhsRate(Real mass, Real diameter, Real temperature, Real omega) {
    detail::require_positive(mass, "mass");
    detail::require_positive(diameter, "diameter");
    detail::require_positive(temperature, "temperature");
    if (!std::isfinite(omega) || omega < 0.5 || omega > 1) {
        throw Error("omega must lie in [0.5, 1]");
    }

    // 同种粒子的约化质量为 m/2；预存参考值，使 K(g) 写成 K_ref*(g/g_ref)^(2-2*omega)。
    g_ref_ = std::sqrt(4 * boltzmann * temperature / mass);
    kernel_ref_ = pi * diameter * diameter * g_ref_ / std::tgamma(2.5 - omega);
    exponent_ = 2 * (1 - omega);
    detail::require_positive(g_ref_, "reference speed");
    detail::require_positive(kernel_ref_, "reference kernel");
}

Real VhsRate::kernel(Real g) const {
    if (!std::isfinite(g) || g < 0) {
        throw Error("invalid relative speed");
    }
    // omega = 1 时直接返回常数 K_ref，也覆盖 g = 0，避免求值 0^0。
    if (exponent_ == 0) {
        return kernel_ref_;
    }
    if (g == 0) {
        return 0;
    }
    const Real q = kernel_ref_ * std::pow(g / g_ref_, exponent_);
    if (!std::isfinite(q)) {
        throw Error("nonfinite VHS kernel");
    }
    return q;
}

} // namespace algoplasma::dsmc
