// SPDX-License-Identifier: Apache-2.0
#include "collision_kernel.hpp"
#include "random.hpp"
#include <algorithm>

namespace algoplasma::dsmc::detail {
namespace {
struct Sums {
    long double x{}, y{}, z{}, square{};
};

// 在固定参考速度下累计一阶、二阶矩，降低大漂移速度造成的消减误差。
Sums sums(std::span<const CollisionParticle> particles, Vec3 reference) {
    Sums result;
    for (const auto& p : particles) {
        const long double x = static_cast<long double>(p.velocity_mps.x) - reference.x;
        const long double y = static_cast<long double>(p.velocity_mps.y) - reference.y;
        const long double z = static_cast<long double>(p.velocity_mps.z) - reference.z;
        result.x += x;
        result.y += y;
        result.z += z;
        result.square += x * x + y * y + z * z;
    }
    return result;
}
} // namespace

CellReport collide_cell(std::span<CollisionParticle> particles, const CollisionCell& cell,
                        const DsmcModel& model, const StepContext& context,
                        const StepOptions& options, StepReport& report) {
    CellReport result;
    result.cell_id = cell.global_id;
    const auto n = particles.size();
    if (n < 2 || context.dt_s == 0) {
        return result;
    }

    const Vec3 reference = particles.front().velocity_mps;
    const auto before = sums(particles, reference);
    const long double mx = before.x / n, my = before.y / n, mz = before.z / n;

    // 先求平均速度，再直接累计相对平均速度的平方，避免用两个大能量之差求热能。
    long double variance_sum = 0;
    for (const auto& p : particles) {
        const long double x = static_cast<long double>(p.velocity_mps.x) - reference.x - mx;
        const long double y = static_cast<long double>(p.velocity_mps.y) - reference.y - my;
        const long double z = static_cast<long double>(p.velocity_mps.z) - reference.z - mz;
        variance_sum += x * x + y * y + z * z;
    }

    // g_ij^2 <= 2 * sum_k |v_k - U|^2；弹性碰撞保持右侧不变。
    // 因此同一步内速度虽会更新，该上界仍适用；附加小余量用于浮点舍入。
    const Real g_max = static_cast<Real>(std::sqrt(2 * variance_sum) * (1 + 1e-10L));
    if (!std::isfinite(g_max)) {
        throw Error("relative-speed bound overflow");
    }
    const Real majorant = model.rate().majorant(g_max);
    if (!std::isfinite(majorant) || majorant < 0) {
        throw Error("invalid collision kernel majorant");
    }
    result.majorant_m3_per_s = majorant;
    if (majorant == 0) {
        return result;
    }

    // 共同的候选强度积分：Lambda * dt = N(N-1)/2 * W * dt / V * K_max。
    // 此处固定单元成员、体积和能量上界；连续时钟并不改变这些弹性碰撞假设。
    const long double expectation = static_cast<long double>(n) * (n - 1) / 2 * model.weight() *
                                    context.dt_s / cell.volume_m3 * majorant;
    const auto budget =
        std::min(options.max_candidates_per_cell, options.max_candidates_total - report.candidates);
    if (!std::isfinite(expectation)) {
        throw Error("nonfinite candidate intensity before commit");
    }

    std::uint64_t rounded_candidates = 0;
    if (options.candidate_schedule == CandidateSchedule::RoundedNtc) {
        // 保持既有 NTC 抽样：整数部分直接保留，小数部分是补一个候选的概率。
        if (expectation > static_cast<long double>(budget)) {
            throw Error("candidate budget exceeded before commit");
        }
        RandomStream rounding(context.seed, context.global_step, cell.global_id, 0,
                              random_purpose::rounding, context.substep);
        const auto integral = std::floor(expectation);
        rounded_candidates = static_cast<std::uint64_t>(integral) +
                             (rounding.uniform() < expectation - integral ? 1U : 0U);
        if (rounded_candidates > budget) {
            throw Error("rounded candidate budget exceeded");
        }
    }

    long double elapsed_hazard = 0;
    for (std::uint64_t event = 0;; ++event) {
        std::optional<Real> time_offset;
        if (options.candidate_schedule == CandidateSchedule::RoundedNtc) {
            if (event == rounded_candidates) {
                break;
            }
        } else {
            // 每个候选（包括拒绝事件）推进指数时钟。U 严格位于 (0,1)。
            // 在积分强度坐标中推进，避免直接计算 1/Lambda 的溢出或下溢。
            RandomStream clock(context.seed, context.global_step, cell.global_id, event,
                               random_purpose::candidate_clock, context.substep);
            const long double wait = -std::log(static_cast<long double>(clock.open_uniform()));
            if (wait >= expectation - elapsed_hazard) {
                break;
            }
            const auto next = elapsed_hazard + wait;
            if (!(next > elapsed_hazard)) {
                throw Error("candidate clock lost numerical resolution; step discarded");
            }
            elapsed_hazard = next;
            // 必须先抽下一候选，才能分辨自然结束与预算不足；绝不截断事件序列。
            if (event >= budget) {
                throw Error("continuous-clock candidate budget exceeded; step discarded");
            }
            time_offset = static_cast<Real>(elapsed_hazard / expectation * context.dt_s);
        }
        ++result.candidates;

        // 先选 i，再从其余 N-1 个粒子中选 j；每个无序粒子对等概率被选中。
        RandomStream select(context.seed, context.global_step, cell.global_id, event,
                            random_purpose::pair_selection, context.substep);
        const auto i = static_cast<std::size_t>(select.index(n));
        auto j = static_cast<std::size_t>(select.index(n - 1));
        if (j >= i) {
            ++j;
        }

        const Vec3 v1 = particles[i].velocity_mps, v2 = particles[j].velocity_mps;
        const Vec3 relative = v1 - v2;
        const Real q = model.rate().kernel(norm(relative));
        if (!std::isfinite(q) || q < 0 || q > majorant) {
            throw Error("collision kernel exceeds its majorant; step discarded");
        }

        // 以 K(g)/K_max 接受候选；超出上界时必须报错，不能把概率强行压到 1。
        RandomStream accept(context.seed, context.global_step, cell.global_id, event,
                            random_purpose::acceptance, context.substep);
        if (accept.uniform() >= q / majorant) {
            ++result.rejected;
            continue;
        }

        // 等质量二体弹性碰撞：保持质心速度，用散射后的相对速度重建双方速度。
        RandomStream scatter(context.seed, context.global_step, cell.global_id, event,
                             random_purpose::scattering, context.substep);
        const Vec3 outgoing = model.scattering().sample(relative, scatter);
        const Vec3 center = v1 * 0.5 + v2 * 0.5;
        const Vec3 a = center + outgoing * 0.5, b = center - outgoing * 0.5;
        if (!finite(a) || !finite(b)) {
            throw Error("nonfinite post-collision velocity");
        }
        particles[i].velocity_mps = a;
        particles[j].velocity_mps = b;
        ++result.accepted;

        if (options.record_events) {
            if (report.events.size() < options.max_event_records) {
                report.events.push_back(
                    {cell.global_id, particles[i].id, particles[j].id, event, {v1, v2}, {a, b},
                     time_offset});
            } else {
                report.events_truncated = true;
            }
        }
    }

    // 相对守恒误差以热运动为尺度，防止很大的整体漂移掩盖热能误差。
    const auto after = sums(particles, reference);
    const long double dx = after.x - before.x, dy = after.y - before.y, dz = after.z - before.z;
    const long double delta_square_com =
        after.square - before.square - 2 * (mx * dx + my * dy + mz * dz);
    const long double momentum_scale = std::sqrt(n * variance_sum);
    result.relative_momentum_error =
        momentum_scale > 0
            ? static_cast<Real>(std::sqrt(dx * dx + dy * dy + dz * dz) / momentum_scale)
            : 0;
    result.relative_energy_error =
        variance_sum > 0 ? static_cast<Real>(std::abs(delta_square_com) / variance_sum) : 0;
    if ((variance_sum == 0 && (dx != 0 || dy != 0 || dz != 0 || after.square != 0)) ||
        !std::isfinite(result.relative_energy_error) ||
        !std::isfinite(result.relative_momentum_error) ||
        result.relative_energy_error > options.conservation_tolerance ||
        result.relative_momentum_error > options.conservation_tolerance) {
        throw Error("elastic conservation check failed; step discarded");
    }

    // 报告中的绝对残差还原到实验室系，并乘以质量和模拟粒子权重。
    const long double factor = static_cast<long double>(model.weight()) * model.species().mass_kg;
    report.momentum_error =
        report.momentum_error + Vec3{static_cast<Real>(factor * dx), static_cast<Real>(factor * dy),
                                     static_cast<Real>(factor * dz)};
    report.energy_error +=
        static_cast<Real>(factor * ((after.square - before.square) / 2 + reference.x * dx +
                                    reference.y * dy + reference.z * dz));
    return result;
}
} // namespace algoplasma::dsmc::detail
