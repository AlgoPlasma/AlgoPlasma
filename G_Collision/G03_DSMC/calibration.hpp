// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "common.hpp"

namespace algoplasma::dsmc {
// 单组分稀薄气体、一级 Chapman-Enskog 的第一 Sonine 近似下的参考动力黏度，单位 Pa s。
// 使用 Bird 参考直径约定；HS: omega=0.5, alpha=1；VHS: alpha=1。
// VSS 的 alpha 改变动量输运截面，因此也进入直径与黏度的换算。
Real reference_viscosity(Real mass_kg, Real diameter_ref_m, Real temperature_ref_k,
                         Real omega = 0.5, Real alpha = 1.0);

// 上式的反函数：由指定的参考动力黏度得到直径，单位 m。
// 所有物理量必须有限且为正，omega in [0.5,1]，alpha >= 1。
Real reference_diameter(Real mass_kg, Real viscosity_ref_pa_s, Real temperature_ref_k,
                        Real omega = 0.5, Real alpha = 1.0);
} // namespace algoplasma::dsmc
