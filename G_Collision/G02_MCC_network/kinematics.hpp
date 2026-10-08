// SPDX-License-Identifier: Apache-2.0
//
// Shared, independently validated N-body final-state kinematics.
//
// All collision algorithms (C02..C08) use these helpers. The algorithms differ
// in their validated semantics (which reactants/products are allowed, which
// energy/angular model applies), not merely in a label.
// 阅读导引：本文件只回答“反应已发生，产物速度怎样分配”。
// 反应是否发生由 engine.hpp 决定；具体推导见 fun_G02_mcc_kinematics.cpp。
// 全部参数采用 SI：质量 kg、动量 kg·m/s、能量 J、速度 m/s。
// CSV 中的 eV 必须先换成 J；产物数组顺序应与模型的产物顺序一致。
#pragma once

#include "common.hpp"
#include "model.hpp"
#include "rng.hpp"

#include <vector>

namespace algoplasma {
namespace mcc {

// 返回每个产物的速度，以及未进入这些产物动能的能量。后者需计入守恒账本。
struct FinalState {
    std::vector<Vec3> velocities;
    // Energy that is not carried by the modeled product particles (radiation or
    // unresolved channels), in joule.
    Real unallocated_energy_j{};
};

// 两产物：先扣除质心整体运动的动能，再把剩余能量分给相对运动。
// ker_min_j 是相对动能的最低要求，不是额外再加一次的释放能量。
// Elastic/inelastic two-body separation in the centre-of-mass frame.
// `total_momentum` is the sum of the reactant momenta; `relative_axis` is the
// incoming relative-velocity direction used by the cone model (it is ignored by
// the isotropic model). `ker_min_j` is the minimum final product relative
// kinetic energy; the call throws when it cannot be met. `available_kinetic_j`
// and `ker_min_j` are compared with a scale-aware tolerance derived from
// std::numeric_limits<double>::epsilon(), never a fixed absolute energy.
[[nodiscard]] FinalState two_body_final_state(
    Real mass1_kg, Real mass2_kg, Vec3 total_momentum, Vec3 relative_axis,
    Real available_kinetic_j, Real ker_min_j, AngularModel angular, Real cosine_min,
    Real cosine_max, CounterRng& rng);

// 共振交换：交换两个输入速度；按物种映射产物的调用者仍需确认顺序。
// Resonant identity exchange: returns {velocity2, velocity1}. Callers that must
// map products by species (rather than by position) should not rely on this
// ordering; see the engine's product-species mapping.
[[nodiscard]] FinalState identity_exchange_final_state(Vec3 velocity1, Vec3 velocity2);

// 多产物：在总动量、总动能约束下统计抽样，不代表分子反应的全部微观细节。
// Statistical n-body phase space with isotropic directions. `available_kinetic_j`
// is the total kinetic energy available to the products; `ker_min_j` is the
// minimum relative kinetic energy. Throws Error when the constraint cannot be
// met. Comparisons use a scale-aware epsilon tolerance.
[[nodiscard]] FinalState n_body_phase_space_final_state(
    const std::vector<Real>& masses_kg, Vec3 total_momentum,
    Real available_kinetic_j, Real ker_min_j, CounterRng& rng);

// 此处 equal_share 仅支持两个产物；质量不同时不意味着两者动能各占一半。
// Equal-share model, defined for exactly two product bodies. It is realized as
// a momentum-conserving two-body separation with an isotropic direction, and it
// leaves no unallocated energy. `ker_min_j` is enforced exactly as in
// two_body_final_state.
[[nodiscard]] FinalState equal_share_final_state(
    const std::vector<Real>& masses_kg, Vec3 total_momentum,
    Real available_kinetic_j, Real ker_min_j, CounterRng& rng);

// 单产物：动量已唯一确定速度，剩余能量不能随意加到速度上。
// Single product: it carries the centre-of-mass motion; the remainder is
// reported as unallocated energy.
[[nodiscard]] FinalState single_product_final_state(
    Real mass_kg, Vec3 total_momentum, Real available_kinetic_j);

} // namespace mcc
} // namespace algoplasma
