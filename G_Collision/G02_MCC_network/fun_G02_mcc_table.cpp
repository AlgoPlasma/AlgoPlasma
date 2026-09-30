// SPDX-License-Identifier: Apache-2.0
//
// 阅读顺序：插值公式 -> 配置文字转换 -> 数据校验 -> 查表 -> 上界。
// 插值只填补数据点之间的值，不能替代可靠的截面或速率系数数据。

#include "table.hpp"

#include "csv.hpp"

#include <algorithm>
#include <cmath>

namespace algoplasma {
namespace mcc {
namespace {

// fraction 表示查询点在相邻节点之间的位置。线性插值连接 y，
// 对数插值连接 log(y)；LogLog 还把 x 轴转成 log(x)。
[[nodiscard]] Real interpolate(const Real x0, const Real x1, const Real y0, const Real y1,
                               const Real x, const Interpolation mode) {
    if (x1 <= x0) return y0;
    if (mode == Interpolation::Linear) {
        const Real fraction = (x - x0) / (x1 - x0);
        return y0 + fraction * (y1 - y0);
    }
    if (mode == Interpolation::LogLinear) {
        const Real fraction = (x - x0) / (x1 - x0);
        return std::exp(std::log(y0) + fraction * (std::log(y1) - std::log(y0)));
    }
    const Real fraction = std::log(x / x0) / std::log(x1 / x0);
    return std::exp(std::log(y0) + fraction * (std::log(y1) - std::log(y0)));
}

} // namespace

Interpolation interpolation_from_string(const std::string& value) {
    const std::string key = to_lower(trim(value));
    if (key == "linear") return Interpolation::Linear;
    if (key == "log-linear" || key == "log_linear" || key == "loglinear") {
        return Interpolation::LogLinear;
    }
    if (key == "log-log" || key == "log_log" || key == "loglog") return Interpolation::LogLog;
    throw Error("unknown interpolation mode '" + value + "'");
}

DomainPolicy domain_policy_from_string(const std::string& value) {
    const std::string key = to_lower(trim(value));
    if (key == "error" || key == "reject") return DomainPolicy::Error;
    if (key == "zero" || key == "none") return DomainPolicy::Zero;
    if (key == "clamp" || key == "hold") return DomainPolicy::Clamp;
    throw Error("unknown out-of-domain policy '" + value + "'");
}

const char* to_string(const Interpolation value) noexcept {
    switch (value) {
    case Interpolation::Linear: return "linear";
    case Interpolation::LogLinear: return "log-linear";
    case Interpolation::LogLog: return "log-log";
    }
    return "unknown";
}

const char* to_string(const DomainPolicy value) noexcept {
    switch (value) {
    case DomainPolicy::Error: return "error";
    case DomainPolicy::Zero: return "zero";
    case DomainPolicy::Clamp: return "clamp";
    }
    return "unknown";
}

// 1. 先拒绝无法安全插值的数据：尺寸不符、节点不足、非有限数、负 y 或乱序 x。
// 严格递增也排除了重复 x，避免插值分母为零。
void Table::validate(const std::string& context) const {
    if (x.size() != y.size()) {
        throw Error(context + ": table has " + std::to_string(x.size()) + " x values and " +
                    std::to_string(y.size()) + " y values");
    }
    if (x.size() < 2U) throw Error(context + ": table needs at least two rows");
    for (std::size_t i = 0; i < x.size(); ++i) {
        if (!is_finite(x[i]) || !is_finite(y[i])) {
            throw Error(context + ": row " + std::to_string(i) + " is NaN or infinite");
        }
        if (y[i] < 0.0) {
            throw Error(context + ": row " + std::to_string(i) + " has a negative value");
        }
        if (x_axis == "temperature" && x[i] < 0.0) {
            throw Error(context + ": temperature grid values must be non-negative (row " +
                        std::to_string(i) + ")");
        }
        if (i > 0U && x[i] <= x[i - 1U]) {
            throw Error(context + ": x values must be strictly increasing (row " +
                        std::to_string(i) + ")");
        }
    }
    // 对数模式另查正值条件，避免运行时计算 log(0) 或 log(负数)。
    if (interpolation == Interpolation::LogLinear || interpolation == Interpolation::LogLog) {
        for (std::size_t i = 0; i < y.size(); ++i) {
            if (y[i] <= 0.0) {
                throw Error(context + ": " + to_string(interpolation) +
                            " interpolation requires strictly positive y values (row " +
                            std::to_string(i) + ")");
            }
        }
    }
    if (interpolation == Interpolation::LogLog) {
        for (std::size_t i = 0; i < x.size(); ++i) {
            if (x[i] <= 0.0) {
                throw Error(context + ": log-log interpolation requires strictly positive x "
                                     "values (row " + std::to_string(i) + ")");
            }
        }
    }
}

// 2. 先处理越界，再找相邻节点。outside 用于记录越界情况，即使策略允许继续。
Real Table::sample(const Real x_value, bool& outside) const {
    outside = false;
    if (x_value < x.front()) {
        outside = true;
        if (below == DomainPolicy::Error) {
            throw Error("table '" + dataset_id + "': x=" + std::to_string(x_value) +
                        " is below the declared domain [" + std::to_string(x.front()) + ", " +
                        std::to_string(x.back()) + "]");
        }
        return below == DomainPolicy::Clamp ? y.front() : 0.0;
    }
    if (x_value > x.back()) {
        outside = true;
        if (above == DomainPolicy::Error) {
            throw Error("table '" + dataset_id + "': x=" + std::to_string(x_value) +
                        " is above the declared domain [" + std::to_string(x.front()) + ", " +
                        std::to_string(x.back()) + "]");
        }
        return above == DomainPolicy::Clamp ? y.back() : 0.0;
    }
    if (x_value == x.back()) return y.back();
    // 二分查找第一个大于 x_value 的节点，和它的前一个节点一起夹住查询点。
    const auto upper = std::upper_bound(x.begin(), x.end(), x_value);
    const std::size_t high = static_cast<std::size_t>(upper - x.begin());
    const std::size_t low = high - 1U;
    return interpolate(x[low], x[high], y[low], y[high], x_value, interpolation);
}

// 3. 三种插值在每个区间内都不超过两端 y 的较大值，因此无需密集扫描。
// 这是整个区间的保守上界，不是只在若干采样点上观察到的最大值。
std::vector<Real> Table::segment_upper_bounds() const {
    std::vector<Real> bounds(x.size() > 0U ? x.size() - 1U : 0U, 0.0);
    for (std::size_t i = 0; i + 1U < x.size(); ++i) {
        bounds[i] = std::max(y[i], y[i + 1U]);
    }
    return bounds;
}

Real Table::upper_bound() const {
    Real maximum = 0.0;
    for (const Real value : y) maximum = std::max(maximum, value);
    return maximum;
}

} // namespace mcc
} // namespace algoplasma
