// SPDX-License-Identifier: Apache-2.0
// 阅读导引：辅助函数 → 两体末态 → 多体末态 → 特殊末态。
// 核心思路是把速度拆成“质心整体运动 + 质心系内的相对运动”。
// 总动量决定前者，剩余可用动能决定后者；随机数只选择允许的运动方向/分配。
#include "kinematics.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <numeric>

namespace algoplasma {
namespace mcc {
namespace {

[[nodiscard]] Real kinetic_energy(const Real mass, const Vec3 velocity) {
    return 0.5 * mass * dot(velocity, velocity);
}

// 浮点计算的相对误差随能量尺度变化。这里用实际参与比较的能量乘机器精度，
// 避免一个固定 J 容差在低能碰撞中大到掩盖错误。
// Scale-aware energy tolerance. The old fixed 1e-18 J floor was ~6.24 eV and
// both masked and rejected legitimate states; derive the tolerance from the
// machine epsilon and the magnitudes actually being compared instead.
[[nodiscard]] Real energy_tolerance(const Real available_kinetic_j, const Real center_energy_j,
                                    const Real ker_min_j) noexcept {
    const Real scale = std::max({std::fabs(available_kinetic_j), std::fabs(center_energy_j),
                                 std::fabs(ker_min_j)});
    return 64.0 * std::numeric_limits<Real>::epsilon() * scale;
}

void require_finite_velocity(const Vec3 velocity) {
    if (!is_finite(velocity.x) || !is_finite(velocity.y) || !is_finite(velocity.z)) {
        throw Error("kinematics produced a non-finite final velocity");
    }
}

// 为入射方向建立垂直坐标基，把抽到的散射角转回三维坐标；
// reference 避开近乎平行的方向，防止叉乘长度接近零。
[[nodiscard]] Vec3 rotate_from_incident(const Vec3 incident, const Real cosine, const Real phi) {
    const Vec3 axis = normalized(incident);
    const Vec3 reference = std::fabs(axis.z) < 0.9 ? Vec3{0.0, 0.0, 1.0} : Vec3{0.0, 1.0, 0.0};
    const Vec3 e1 = normalized(cross(reference, axis));
    const Vec3 e2 = cross(axis, e1);
    const Real sine = std::sqrt(clamp(1.0 - cosine * cosine, 0.0, 1.0));
    return axis * cosine + e1 * (sine * std::cos(phi)) + e2 * (sine * std::sin(phi));
}

// Cone 在指定 cos(theta) 区间内均匀抽样；否则使用整个球面的各向同性方向。
[[nodiscard]] Vec3 sample_relative_direction(const Vec3 incident, const AngularModel angular,
                                             const Real cosine_min, const Real cosine_max,
                                             CounterRng& rng) {
    if (angular == AngularModel::Cone) {
        const Real cosine = cosine_min + (cosine_max - cosine_min) * rng.uniform_open();
        return rotate_from_incident(incident, clamp(cosine, -1.0, 1.0), two_pi * rng.uniform_open());
    }
    return rng.isotropic_direction();
}

} // namespace

// ── 两体末态：动量固定质心速度，能量固定相对速度大小 ──
FinalState two_body_final_state(const Real mass1_kg, const Real mass2_kg,
                                const Vec3 total_momentum, const Vec3 relative_axis,
                                const Real available_kinetic_j, const Real ker_min_j,
                                const AngularModel angular, const Real cosine_min,
                                const Real cosine_max, CounterRng& rng) {
    FinalState state;
    state.velocities.resize(2);
    // V_cm = P / (m1 + m2)，K_cm = P^2 / [2(m1 + m2)]。
    // 可用总动能必须先扣除 K_cm，剩余部分才能用于两产物分离。
    const Real total_mass = mass1_kg + mass2_kg;
    const Vec3 center_velocity = total_momentum / total_mass;
    require_finite_velocity(center_velocity);
    const Real center_energy = kinetic_energy(total_mass, center_velocity);
    const Real relative_available = available_kinetic_j - center_energy;
    const Real tolerance = energy_tolerance(available_kinetic_j, center_energy, ker_min_j);
    if (relative_available < -tolerance) {
        throw Error("two-body final state has negative available relative energy");
    }
    if (relative_available + tolerance < ker_min_j) {
        throw Error("two-body final state cannot satisfy ker_min_ev");
    }
    const Real nonnegative = std::max(relative_available, 0.0);
    // 约化质量 mu = m1*m2/(m1+m2)，相对动能 E_rel = mu*g^2/2。
    const Real reduced = mass1_kg * mass2_kg / total_mass;
    const Real relative_speed = std::sqrt(2.0 * nonnegative / reduced);
    const Vec3 direction = norm(relative_axis) == 0.0
        ? rng.isotropic_direction()
        : sample_relative_direction(relative_axis, angular, cosine_min, cosine_max, rng);
    const Vec3 relative = direction * relative_speed;
    // 相对速度按对方质量的比例分配；两项动量一正一负，恰好抵消。
    state.velocities[0] = center_velocity + relative * (mass2_kg / total_mass);
    state.velocities[1] = center_velocity - relative * (mass1_kg / total_mass);
    require_finite_velocity(state.velocities[0]);
    require_finite_velocity(state.velocities[1]);
    const Real final_energy = kinetic_energy(mass1_kg, state.velocities[0]) +
                              kinetic_energy(mass2_kg, state.velocities[1]);
    state.unallocated_energy_j = std::max(available_kinetic_j - final_energy, 0.0);
    if (!is_finite(state.unallocated_energy_j)) {
        throw Error("two-body final state has a non-finite unallocated energy");
    }
    return state;
}

// ── 共振交换：速度交换本身不需要再抽一个散射角 ──
FinalState identity_exchange_final_state(const Vec3 velocity1, const Vec3 velocity2) {
    FinalState state;
    state.velocities = {velocity2, velocity1};
    return state;
}

// ── 多体末态：先构造零总动量的随机速度，再统一缩放到所需能量 ──
FinalState n_body_phase_space_final_state(const std::vector<Real>& masses_kg,
                                          const Vec3 total_momentum,
                                          const Real available_kinetic_j, const Real ker_min_j,
                                          CounterRng& rng) {
    const std::size_t count = masses_kg.size();
    if (count == 0U) throw Error("phase-space final state needs at least one product");
    FinalState state;
    state.velocities.resize(count);
    if (count == 1U) {
        return single_product_final_state(masses_kg.front(), total_momentum, available_kinetic_j);
    }
    const Real total_mass = std::accumulate(masses_kg.begin(), masses_kg.end(), 0.0);
    const Vec3 center_velocity = total_momentum / total_mass;
    require_finite_velocity(center_velocity);
    const Real center_energy = kinetic_energy(total_mass, center_velocity);
    const Real relative_available = available_kinetic_j - center_energy;
    const Real tolerance = energy_tolerance(available_kinetic_j, center_energy, ker_min_j);
    if (relative_available < -tolerance) {
        throw Error("phase-space final state has negative available relative energy");
    }
    if (relative_available + tolerance < ker_min_j) {
        throw Error("phase-space final state cannot satisfy ker_min_ev");
    }

    // 1. 正态速度按 1/sqrt(m) 缩放，在质量加权坐标中保持各向同性。
    // 这是一种统计末态模型；输入反应表须说明采用这一能量分配假设。
    std::vector<Vec3> relative(count);
    Vec3 weighted_mean{};
    for (std::size_t i = 0; i < count; ++i) {
        const Real scale = 1.0 / std::sqrt(masses_kg[i]);
        relative[i] = rng.random_vector() * scale;
        weighted_mean += relative[i] * masses_kg[i];
    }
    // 2. 减去质量加权平均速度，使 sum(m_i*u_i)=0，不改变质心运动。
    weighted_mean = weighted_mean / total_mass;
    Real raw_energy = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        relative[i] -= weighted_mean;
        raw_energy += kinetic_energy(masses_kg[i], relative[i]);
    }
    if (!(raw_energy > 0.0)) throw Error("phase-space sampling produced a zero-energy state");
    // 3. 动能与速度平方成正比，所以统一乘 sqrt(E_target/E_raw)。
    // 再加回质心速度，便同时满足指定的总动量与总动能。
    const Real multiplier = std::sqrt(std::max(relative_available, 0.0) / raw_energy);
    Real final_energy = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        state.velocities[i] = center_velocity + relative[i] * multiplier;
        require_finite_velocity(state.velocities[i]);
        final_energy += kinetic_energy(masses_kg[i], state.velocities[i]);
    }
    state.unallocated_energy_j = std::max(available_kinetic_j - final_energy, 0.0);
    if (!is_finite(state.unallocated_energy_j)) {
        throw Error("phase-space final state has a non-finite unallocated energy");
    }
    return state;
}

// ── equal_share：只允许两个产物，沿用严格守恒的两体求解 ──
// 两产物在质心系中动量大小相等；质量不同，动能一般不相等。
FinalState equal_share_final_state(const std::vector<Real>& masses_kg, const Vec3 total_momentum,
                                   const Real available_kinetic_j, const Real ker_min_j,
                                   CounterRng& rng) {
    if (masses_kg.size() != 2U) {
        throw Error("equal_share is only defined for exactly two product particles");
    }
    // Momentum conservation fixes the two product speeds for a given relative
    // energy, so equal_share reduces to the two-body separation with an
    // isotropic direction and no unallocated remainder. The shared helper
    // enforces ker_min_j with the scale-aware tolerance.
    FinalState state = two_body_final_state(masses_kg[0], masses_kg[1], total_momentum,
                                            Vec3{0.0, 0.0, 0.0}, available_kinetic_j, ker_min_j,
                                            AngularModel::Isotropic, 0.0, 0.0, rng);
    state.unallocated_energy_j = 0.0;
    return state;
}

// ── 单产物：v=P/m 已固定，剩余能量单独记账 ──
// 这里不模拟光子等未解析对象的轨迹；由引擎计入能量账本。
FinalState single_product_final_state(const Real mass_kg, const Vec3 total_momentum,
                                      const Real available_kinetic_j) {
    FinalState state;
    state.velocities.resize(1);
    state.velocities[0] = total_momentum / mass_kg;
    require_finite_velocity(state.velocities[0]);
    state.unallocated_energy_j =
        std::max(available_kinetic_j - kinetic_energy(mass_kg, state.velocities[0]), 0.0);
    if (!is_finite(state.unallocated_energy_j)) {
        throw Error("single-product final state has a non-finite unallocated energy");
    }
    return state;
}

} // namespace mcc
} // namespace algoplasma
