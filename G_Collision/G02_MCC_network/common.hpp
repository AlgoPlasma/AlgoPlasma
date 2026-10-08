// SPDX-License-Identifier: Apache-2.0
//
// 阅读指引：本文件提供全模块共用的数值类型、单位常量和三维向量。
// 先看 ID 与单位，再看 Vec3；具体碰撞物理由 engine 和 kinematics 实现。

//
// G02_MCC_network - common value types and physical constants.
//
// Internal unit convention used by the whole module:
//   energy        eV        (converted to joule with elementary_charge_c)
//   temperature   K
//   mass          kg
//   length        m
//   time          s
//   velocity      m/s
//   cross section m^2
//   2-body rate   m^3/s
//   3-body rate   m^6/s
#pragma once

#include <cmath>
#include <cstdint>
#include <limits>
#include <stdexcept>
#include <string>

namespace algoplasma {
namespace mcc {

// 1. 数值与编号：ID 是模型中的标识，不保证等于 vector 的下标。
using Real = double;
using SpeciesId = std::uint16_t;
using StateId = std::uint16_t;
using ReactionId = std::uint32_t;

// 这些最大整数值是“未指定”的哨兵，不能当成 CSV 中的有效编号。
// invalid_state 本身不表示基态；需要基态时应查询 StateRegistry。
inline constexpr SpeciesId invalid_species = std::numeric_limits<SpeciesId>::max();
inline constexpr StateId invalid_state = std::numeric_limits<StateId>::max();
inline constexpr ReactionId invalid_reaction = std::numeric_limits<ReactionId>::max();

// 2. 单位换算：1 eV = elementary_charge_c J；温度通过 k_B T 转成能量。
// 模型参数常用 eV，而动量/动能运算使用 kg、m/s、J，必须显式换算。
inline constexpr Real elementary_charge_c = 1.602176634e-19;
inline constexpr Real boltzmann_j_per_k = 1.380649e-23;
inline constexpr Real electron_mass_kg = 9.1093837139e-31;
inline constexpr Real atomic_mass_kg = 1.66053906892e-27;
inline constexpr Real two_pi = 6.283185307179586476925286766559;

// 3. 三维向量只保存三个分量，不携带单位；是速度还是动量由使用处决定。
struct Vec3 {
    Real x{};
    Real y{};
    Real z{};
};

[[nodiscard]] constexpr Vec3 operator+(Vec3 a, Vec3 b) noexcept {
    return {a.x + b.x, a.y + b.y, a.z + b.z};
}

[[nodiscard]] constexpr Vec3 operator-(Vec3 a, Vec3 b) noexcept {
    return {a.x - b.x, a.y - b.y, a.z - b.z};
}

[[nodiscard]] constexpr Vec3 operator-(Vec3 a) noexcept { return {-a.x, -a.y, -a.z}; }

[[nodiscard]] constexpr Vec3 operator*(Vec3 a, Real s) noexcept {
    return {a.x * s, a.y * s, a.z * s};
}

[[nodiscard]] constexpr Vec3 operator*(Real s, Vec3 a) noexcept { return a * s; }
[[nodiscard]] constexpr Vec3 operator/(Vec3 a, Real s) noexcept { return a * (1.0 / s); }

constexpr Vec3& operator+=(Vec3& a, Vec3 b) noexcept {
    a = a + b;
    return a;
}

constexpr Vec3& operator-=(Vec3& a, Vec3 b) noexcept {
    a = a - b;
    return a;
}

// 点积 dot(a,a) 给出长度平方；叉积 cross 用于构造垂直方向。
[[nodiscard]] constexpr Real dot(Vec3 a, Vec3 b) noexcept {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

[[nodiscard]] constexpr Vec3 cross(Vec3 a, Vec3 b) noexcept {
    return {a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x};
}

[[nodiscard]] inline Real norm(Vec3 a) noexcept { return std::sqrt(dot(a, a)); }

// 零向量没有方向，这里约定返回 x 轴单位向量，避免除以零。
[[nodiscard]] inline Vec3 normalized(Vec3 a) noexcept {
    const Real magnitude = norm(a);
    return magnitude > 0.0 ? a / magnitude : Vec3{1.0, 0.0, 0.0};
}

[[nodiscard]] constexpr Real clamp(Real value, Real low, Real high) noexcept {
    return value < low ? low : (value > high ? high : value);
}

[[nodiscard]] inline bool is_finite(Real value) noexcept { return std::isfinite(value); }

// Error raised for every recoverable failure. Messages carry enough context
// (file, line, reaction, species) to locate the problem. Nothing is committed
// when an Error escapes a public entry point.
class Error : public std::runtime_error {
public:
    explicit Error(const std::string& message) : std::runtime_error(message) {}
};

} // namespace mcc
} // namespace algoplasma
