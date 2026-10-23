// SPDX-License-Identifier: Apache-2.0
#pragma once

#include "common.hpp"
#include <initializer_list>

namespace algoplasma::dsmc {
// 固定数值是随机重放约定的一部分；新增用途应使用新的值。
namespace random_purpose {
inline constexpr std::uint64_t rounding = 0;
inline constexpr std::uint64_t pair_selection = 1;
inline constexpr std::uint64_t acceptance = 2;
inline constexpr std::uint64_t scattering = 3;
inline constexpr std::uint64_t candidate_clock = 4;
} // namespace random_purpose

// 用种子、时间步、单元、事件和用途标识确定局部随机流，避免依赖粒子存储顺序。
// 选对、接受判定与散射使用不同的 purpose，互不消耗对方的随机数。
class RandomStream {
public:
    RandomStream(std::uint64_t seed, std::uint64_t step = 0, CellId cell = 0,
                 std::uint64_t event = 0, std::uint64_t purpose = 0, std::uint32_t substep = 0) {
        state_ = mix(seed);
        for (auto key : {step, cell, event, purpose, std::uint64_t{substep}}) {
            state_ = mix(state_ ^ mix(key));
        }
    }

    std::uint64_t next() {
        state_ += 0x9e3779b97f4a7c15ULL;
        return mix(state_);
    }

    // [0, 1) 用于概率判定；(0, 1) 用于对数等不能取端点的变换。
    Real uniform() {
        return static_cast<Real>(next() >> 11) * 0x1.0p-53;
    }

    Real open_uniform() {
        return (static_cast<Real>(next() >> 12) + 0.5) * 0x1.0p-52;
    }

    std::uint64_t index(std::uint64_t n) {
        if (!n) {
            throw Error("cannot sample an empty index range");
        }

        // 丢弃不足一个完整余数周期的区间，消除直接取模造成的抽样偏差。
        const auto threshold = (std::uint64_t{0} - n) % n;
        for (;;) {
            const auto x = next();
            if (x >= threshold) {
                return x % n;
            }
        }
    }

private:
    static std::uint64_t mix(std::uint64_t x) {
        x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
        x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
        return x ^ (x >> 31);
    }

    std::uint64_t state_{};
};
} // namespace algoplasma::dsmc
