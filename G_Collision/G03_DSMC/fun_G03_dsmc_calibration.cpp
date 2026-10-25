// SPDX-License-Identifier: Apache-2.0
#include "calibration.hpp"

namespace algoplasma::dsmc {
namespace {
Real viscosity_scale(Real mass, Real temperature, Real omega, Real alpha) {
    detail::require_positive(mass, "mass");
    detail::require_positive(temperature, "reference temperature");
    if (!std::isfinite(omega) || omega < 0.5 || omega > 1) {
        throw Error("omega must lie in [0.5, 1]");
    }
    if (!std::isfinite(alpha) || alpha < 1) {
        throw Error("alpha must be finite and >= 1");
    }
    // mu_ref * d_ref^2；保留与原标定相同的数值求值顺序。
    const Real calibration = 5 * ((alpha + 1) / alpha) * (alpha + 2) *
                             std::sqrt(mass * boltzmann * temperature / pi) /
                             (4 * (5 - 2 * omega) * (7 - 2 * omega));
    detail::require_positive(calibration, "viscosity calibration");
    return calibration;
}
} // namespace

Real reference_viscosity(Real mass, Real diameter, Real temperature, Real omega, Real alpha) {
    detail::require_positive(diameter, "reference diameter");
    const Real viscosity = viscosity_scale(mass, temperature, omega, alpha) / (diameter * diameter);
    detail::require_positive(viscosity, "reference viscosity");
    return viscosity;
}

Real reference_diameter(Real mass, Real viscosity, Real temperature, Real omega, Real alpha) {
    detail::require_positive(viscosity, "reference viscosity");
    const Real diameter = std::sqrt(viscosity_scale(mass, temperature, omega, alpha) / viscosity);
    detail::require_positive(diameter, "reference diameter");
    return diameter;
}
} // namespace algoplasma::dsmc
