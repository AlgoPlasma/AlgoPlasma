// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <cmath>
#include <cstdint>
#include <limits>
#include <numbers>
#include <stdexcept>
#include <string>

namespace algoplasma::dsmc {
using Real = double;
using ParticleId = std::uint64_t;
using CellId = std::uint64_t;
using SpeciesId = std::uint32_t;
inline constexpr Real boltzmann = 1.380649e-23;
inline constexpr Real pi = std::numbers::pi_v<Real>;

class Error : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

namespace detail {
inline void require_positive(Real value, const char* name) {
    if (!std::isfinite(value) || !(value > 0)) {
        throw Error(std::string(name) + " must be finite and positive");
    }
}
} // namespace detail

struct Vec3 {
    Real x{}, y{}, z{};
};

inline Vec3 operator+(Vec3 a, Vec3 b) {
    return {a.x + b.x, a.y + b.y, a.z + b.z};
}

inline Vec3 operator-(Vec3 a, Vec3 b) {
    return {a.x - b.x, a.y - b.y, a.z - b.z};
}

inline Vec3 operator*(Vec3 a, Real b) {
    return {a.x * b, a.y * b, a.z * b};
}

inline Vec3 operator/(Vec3 a, Real b) {
    return {a.x / b, a.y / b, a.z / b};
}

inline Real dot(Vec3 a, Vec3 b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

inline Vec3 cross(Vec3 a, Vec3 b) {
    return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}

inline Real norm(Vec3 a) {
    return std::hypot(a.x, a.y, a.z);
}

inline bool finite(Vec3 a) {
    return std::isfinite(a.x) && std::isfinite(a.y) && std::isfinite(a.z);
}

} // namespace algoplasma::dsmc
