// SPDX-License-Identifier: Apache-2.0
#include "model.hpp"
#include "calibration.hpp"
#include <utility>

namespace algoplasma::dsmc {
DsmcModel::DsmcModel(Species species, Real weight, const ElasticModelParameters& p)
    : species_(std::move(species)), weight_(weight) {
    detail::require_positive(species_.mass_kg, "species mass");
    detail::require_positive(weight_, "weight");
    if (species_.name.empty()) {
        throw Error("species name is empty");
    }
    if (species_.charge_state != 0) {
        throw Error("this version supports neutral elastic collisions only");
    }
    const char* type;
    switch (p.type) {
    case ElasticModel::HS:
        if (p.omega != 0.5 || p.alpha != 1) {
            throw Error("HS requires omega=0.5 and alpha=1");
        }
        type = "HS";
        break;
    case ElasticModel::VHS:
        if (p.alpha != 1) {
            throw Error("VHS requires alpha=1");
        }
        type = "VHS";
        break;
    case ElasticModel::VSS:
        type = "VSS";
        break;
    default:
        throw Error("unknown elastic model");
    }

    const Real viscosity = reference_viscosity(species_.mass_kg, p.diameter_ref_m,
                                              p.temperature_ref_k, p.omega, p.alpha);
    if (p.type == ElasticModel::HS) {
        rate_ = std::make_unique<HardSphereRate>(p.diameter_ref_m);
    } else {
        rate_ = std::make_unique<VhsRate>(species_.mass_kg, p.diameter_ref_m,
                                        p.temperature_ref_k, p.omega);
    }
    if (p.type == ElasticModel::VSS) {
        scattering_ = std::make_unique<VssScattering>(p.alpha);
    } else {
        scattering_ = std::make_unique<IsotropicScattering>();
    }
    properties_ = {type, p.diameter_ref_m, p.temperature_ref_k, p.omega, p.alpha, viscosity};
}
} // namespace algoplasma::dsmc
