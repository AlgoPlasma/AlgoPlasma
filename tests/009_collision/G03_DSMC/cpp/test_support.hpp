// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "dsmc.hpp"
#include <algorithm>
#include <bit>
#include <cmath>
#include <iostream>
#include <iomanip>
#include <limits>
#include <random>
#include <span>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace test {
using namespace algoplasma::dsmc;
inline const Species argon{0, "Ar", 6.6335209e-26, 0};

inline void require(bool condition, const std::string& message) {
    if (!condition) {
        throw std::runtime_error(message);
    }
}

inline void close(long double actual, long double expected, long double relative,
                  long double absolute, const std::string& message) {
    if (!(std::abs(actual - expected) <= absolute + relative * std::abs(expected))) {
        std::ostringstream description;
        description << std::setprecision(18) << message << ": got " << actual
                    << ", expected " << expected;
        throw std::runtime_error(description.str());
    }
}

template <class Function>
void rejects(Function&& function, const std::string& message) {
    try {
        function();
    } catch (const Error&) {
        return;
    }
    throw std::runtime_error(message + ": expected dsmc::Error");
}

inline ElasticModelParameters parameters(ElasticModel type) {
    return {type, 4.0e-10, 300.0, type == ElasticModel::HS ? 0.5 : 0.81,
            type == ElasticModel::VSS ? 1.4 : 1.0};
}

inline CylindricalGrid grid() {
    return {{0.0, 1e-3, 3e-3}, {0.0, 0.7, 2*pi}, {0.0, 2e-3, 5e-3},
            AngularBoundary::periodic, 37};
}

inline CylindricalGrid single_cell() {
    return {{0.0, 1e-3}, {0.0, 2*pi}, {0.0, 1e-3}, AngularBoundary::periodic, 11};
}

// 初态使用独立的标准库生成器；粒子位置覆盖八个非均匀三维单元。
inline std::vector<CylindricalParticleState> cloud(std::size_t count, Real drift = 0) {
    std::mt19937_64 generator(1234);
    std::normal_distribution<Real> thermal(0, 250);
    std::vector<CylindricalParticleState> particles;
    for (std::size_t i = 0; i < count; ++i) {
        const Real r = i % 2 ? 2e-3 : 0.5e-3;
        const Real theta = (i / 2) % 2 ? 2.0 : 0.3;
        const Real z = (i / 4) % 2 ? 3e-3 : 1e-3;
        const Vec3 velocity{drift + thermal(generator), thermal(generator), thermal(generator)};
        particles.push_back({static_cast<ParticleId>(100 + i), argon.id, {r, theta, z},
                             to_cylindrical_velocity(velocity, theta)});
    }
    return particles;
}

inline bool same(Real a, Real b) {
    return std::bit_cast<std::uint64_t>(a) == std::bit_cast<std::uint64_t>(b);
}

inline bool same(const CylindricalParticleState& a, const CylindricalParticleState& b) {
    return a.id == b.id && a.species_id == b.species_id &&
           same(a.position.r_m, b.position.r_m) && same(a.position.theta_rad, b.position.theta_rad) &&
           same(a.position.z_m, b.position.z_m) &&
           same(a.velocity_mps.vr_mps, b.velocity_mps.vr_mps) &&
           same(a.velocity_mps.vtheta_mps, b.velocity_mps.vtheta_mps) &&
           same(a.velocity_mps.vz_mps, b.velocity_mps.vz_mps);
}

inline bool same(std::span<const CylindricalParticleState> a,
                 std::span<const CylindricalParticleState> b) {
    return a.size() == b.size() && std::equal(a.begin(), a.end(), b.begin(),
        [](const auto& x, const auto& y) { return same(x, y); });
}

struct Moments {
    long double x{}, y{}, z{}, square{};
};

// 固定参考速度下直接累计，避免强共同漂移掩盖热运动尺度的误差。
inline Moments moments(std::span<const CylindricalParticleState> particles, Vec3 reference = {}) {
    Moments result;
    for (const auto& p : particles) {
        const auto v = to_cartesian_velocity(p.velocity_mps, p.position.theta_rad);
        const long double x = static_cast<long double>(v.x) - reference.x;
        const long double y = static_cast<long double>(v.y) - reference.y;
        const long double z = static_cast<long double>(v.z) - reference.z;
        result.x += x;
        result.y += y;
        result.z += z;
        result.square += x*x + y*y + z*z;
    }
    return result;
}

inline void conserved(Moments before, Moments after, std::size_t count, long double tolerance) {
    const auto scale = std::sqrt(count * before.square);
    const auto difference = std::hypot(after.x-before.x, after.y-before.y, after.z-before.z);
    require(difference <= tolerance * scale, "global momentum conservation at thermal scale");
    close(after.square, before.square, tolerance, 0, "fixed-frame kinetic energy conservation");
}

struct Statistics {
    std::size_t count{};
    long double mean{}, m2{};
    void add(long double value) {
        ++count;
        const auto delta = value - mean;
        mean += delta / count;
        m2 += delta * (value - mean);
    }
    long double variance() const { return m2 / (count - 1); }
};

void models();
void scattering();
void random_sampling();
void geometry();
void conservation();
void schedules();
void replay();
void errors();
} // namespace test
