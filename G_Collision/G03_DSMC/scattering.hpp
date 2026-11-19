// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "random.hpp"

namespace algoplasma::dsmc {
// 给定统一笛卡尔基底下的入射相对速度，抽样保持模长的出射相对速度。
// 粒子种类、数量、位置和内能均不由这个接口改变。
class ElasticScattering {
public:
    virtual ~ElasticScattering() = default;
    virtual Vec3 sample(Vec3 incoming_relative, RandomStream& rng) const = 0;
};

class IsotropicScattering final : public ElasticScattering {
public:
    Vec3 sample(Vec3 incoming_relative, RandomStream& rng) const override;
};

class VssScattering final : public ElasticScattering {
public:
    explicit VssScattering(Real alpha);
    Vec3 sample(Vec3 incoming_relative, RandomStream& rng) const override;

private:
    Real inverse_alpha_;
};
} // namespace algoplasma::dsmc
