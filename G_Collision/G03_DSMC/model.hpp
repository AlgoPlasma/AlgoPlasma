// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "rate.hpp"
#include "scattering.hpp"
#include <memory>

namespace algoplasma::dsmc {
struct Species {
    SpeciesId id{};
    std::string name;
    Real mass_kg{};
    std::int32_t charge_state{}; // 电荷数 Z；当前版本仅允许中性分子 Z = 0。
};

enum class ElasticModel { HS, VHS, VSS };

// 程序化输入，仅含物理量，不规定其来源和文件格式。
// HS 要求 omega=0.5、alpha=1；VHS 要求 alpha=1；VSS 可独立指定两者。
struct ElasticModelParameters {
    ElasticModel type{ElasticModel::HS};
    Real diameter_ref_m{};
    Real temperature_ref_k{300.0};
    Real omega{0.5};
    Real alpha{1.0};
};

struct ModelProperties {
    std::string type;
    Real diameter_ref_m{}, temperature_ref_k{}, omega{}, alpha{}, viscosity_ref_pa_s{};
};

// 持有单物种参数、统一粒子权重和模型组件，供步进器只读访问。
// 由 HS/VHS/VSS 参数直接构造；模型内部组合碰撞率与散射角分布。
class DsmcModel {
public:
    DsmcModel(Species species, Real weight, const ElasticModelParameters& parameters);

    const Species& species() const noexcept {
        return species_;
    }

    Real weight() const noexcept {
        return weight_;
    }

    const PairRateModel& rate() const noexcept {
        return *rate_;
    }

    const ElasticScattering& scattering() const noexcept {
        return *scattering_;
    }

    const ModelProperties& properties() const noexcept {
        return properties_;
    }

private:
    Species species_;
    Real weight_;
    std::unique_ptr<const PairRateModel> rate_;
    std::unique_ptr<const ElasticScattering> scattering_;
    ModelProperties properties_;
};
} // namespace algoplasma::dsmc
