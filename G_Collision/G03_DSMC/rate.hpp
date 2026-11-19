// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "common.hpp"

namespace algoplasma::dsmc {
// 碰撞率核 K(g) = sigma(g) * g，单位 m^3/s；相对速率 g 的单位为 m/s。
// 模型只定义物理函数，不读取参数文件，也不管理粒子权重。
class PairRateModel {
public:
    virtual ~PairRateModel() = default;
    virtual Real kernel(Real g) const = 0;

    // 必须覆盖整个区间 0 <= g <= g_max，而非仅给出端点估计。
    virtual Real majorant(Real g_max) const = 0;
};

class HardSphereRate final : public PairRateModel {
public:
    explicit HardSphereRate(Real diameter_m);
    Real kernel(Real g) const override;

    Real majorant(Real g_max) const override {
        return kernel(g_max);
    }

private:
    Real cross_section_m2_;
};

// 单组分 VHS 速率；VSS 复用此速率并另外指定散射角分布。
// omega 限于 [0.5, 1]，此时 K(g) 单调不减，可直接使用端点上界。
class VhsRate final : public PairRateModel {
public:
    VhsRate(Real mass_kg, Real diameter_ref_m, Real temperature_ref_k, Real omega);
    Real kernel(Real g) const override;

    Real majorant(Real g_max) const override {
        return kernel(g_max);
    }

private:
    Real g_ref_, kernel_ref_, exponent_;
};
} // namespace algoplasma::dsmc
