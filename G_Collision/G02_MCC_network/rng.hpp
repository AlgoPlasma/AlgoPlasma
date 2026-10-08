// SPDX-License-Identifier: Apache-2.0
//
// Counter-based random numbers.
//
// Every draw is addressed by an explicit tuple:
//   (seed, global_step, particle_id, event_index, slot)
// so replay does not depend on thread, MPI rank, loop order or the order in
// which background components were supplied by the caller.
// 阅读导引：先看构造函数的五元组，再看 uniform_open / normal / isotropic_direction。
// CounterRng 是计数器随机流：同样的五元组和取数次数得到同样的伪随机数。
// slot 区分抽时间、选通道、抽方向等用途；宿主需保持粒子 id 稳定且唯一。
#pragma once

#include "common.hpp"

#include <cstdint>

namespace algoplasma {
namespace mcc {

class CounterRng {
public:
    CounterRng(const std::uint64_t seed, const std::uint64_t global_step,
               const std::uint64_t particle_id, const std::uint64_t event_index,
               const std::uint64_t slot) noexcept
        : key_(mix(seed ^ tag_seed)) {
        // Give every tuple position its own domain and mix after each field.
        // A commutative XOR of fields would reuse a stream when event_index
        // and slot are swapped, correlating the clock and acceptance draws.
        // 每个维度有独立标记，并按固定顺序逐层混合；交换事件号和用途号不会复用流。
        key_ = mix(key_ ^ mix(global_step ^ tag_step));
        key_ = mix(key_ ^ mix(particle_id ^ tag_particle));
        key_ = mix(key_ ^ mix(event_index ^ tag_event));
        key_ = mix(key_ ^ mix(slot ^ tag_slot));
    }

    // 每取一次推进局部 counter；不读共享随机状态，因此不依赖线程执行先后。
    [[nodiscard]] std::uint64_t next_u64() noexcept {
        return mix(key_ + counter_++ * 0x9e3779b97f4a7c15ULL);
    }

    // 取高 53 位映射到单位区间，半格偏移避免产生 0，供对数抽样使用。
    // 浮点舍入仍可能落在上端点；引擎对由此得到的无限等待时间有处理。
    [[nodiscard]] Real uniform_open() noexcept {
        constexpr Real scale = 1.0 / 9007199254740992.0;
        return (static_cast<Real>(next_u64() >> 11U) + 0.5) * scale;
    }

    // Box–Muller：两个均匀随机数变成两个均值 0、方差 1 的正态随机数。
    // 一次返回一个，另一个暂存 spare_，下一次直接复用。
    [[nodiscard]] Real normal() noexcept {
        if (has_spare_) {
            has_spare_ = false;
            return spare_;
        }
        const Real radius = std::sqrt(-2.0 * std::log(uniform_open()));
        const Real angle = two_pi * uniform_open();
        spare_ = radius * std::sin(angle);
        has_spare_ = true;
        return radius * std::cos(angle);
    }

    // 各向同性：均匀抽 cos(theta) 和方位角 phi，球面上等面积区域概率相同。
    // 直接均匀抽 theta 会使方向在两极聚集。返回的是长度为 1 的方向，不是速度。
    [[nodiscard]] Vec3 isotropic_direction() noexcept {
        const Real mu = 2.0 * uniform_open() - 1.0;
        const Real phi = two_pi * uniform_open();
        const Real transverse = std::sqrt(clamp(1.0 - mu * mu, 0.0, 1.0));
        return {transverse * std::cos(phi), transverse * std::sin(phi), mu};
    }

    // 三个独立正态分量；常用于生成热速度或多体末态，不是单位向量。
    [[nodiscard]] Vec3 random_vector() noexcept { return {normal(), normal(), normal()}; }

    // 哈希式派生标识工具，不保证无碰撞；批量层另有全局唯一编号分配流程。
    [[nodiscard]] static std::uint64_t child_id(const std::uint64_t parent,
                                                const std::uint64_t step,
                                                const std::uint64_t ordinal) noexcept {
        return mix(parent ^ mix(step + 0x94d049bb133111ebULL) ^
                   mix(ordinal + 0x2545f4914f6cdd1dULL));
    }

    // Deterministic stream used by non-event sampling (background order
    // independence and replay tests).
    // 同一物种绑定同一子流，使背景输入列表重新排序后抽样仍可复现。
    [[nodiscard]] static std::uint64_t stream_slot(const std::uint64_t base,
                                                   const std::uint64_t species) noexcept {
        return mix(base ^ mix(species + 0x2545f4914f6cdd1dULL));
    }

private:
    // Domain labels identify tuple positions, rather than physical parameters.
    static constexpr std::uint64_t tag_seed = 0xa0761d6478bd642fULL;
    static constexpr std::uint64_t tag_step = 0xe7037ed1a0b428dbULL;
    static constexpr std::uint64_t tag_particle = 0x8ebc6af09c88c6e3ULL;
    static constexpr std::uint64_t tag_event = 0x589965cc75374cc3ULL;
    static constexpr std::uint64_t tag_slot = 0x1d8e4e27c47d124fULL;

    // 位混合把相邻整数打散为伪随机位模式；这些常数不是物理参数。
    [[nodiscard]] static std::uint64_t mix(std::uint64_t value) noexcept {
        value += 0x9e3779b97f4a7c15ULL;
        value = (value ^ (value >> 30U)) * 0xbf58476d1ce4e5b9ULL;
        value = (value ^ (value >> 27U)) * 0x94d049bb133111ebULL;
        return value ^ (value >> 31U);
    }

    std::uint64_t key_{};
    std::uint64_t counter_{};
    bool has_spare_{false};
    Real spare_{};
};

} // namespace mcc
} // namespace algoplasma
