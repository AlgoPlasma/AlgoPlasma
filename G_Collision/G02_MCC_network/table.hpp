// SPDX-License-Identifier: Apache-2.0
//
// 阅读指引：Table 将离散数据点连成可查询的曲线。
// validate 检查数据，sample 插值，upper_bound 系列为碰撞频率上界提供依据。

//
// Versioned, validated lookup tables (cross sections and rate coefficients).
//
// A table is a strictly increasing x grid with a non-negative y value. Three
// analytic interpolation modes are used to build a *conservative* upper bound
// on every analytic segment; the compiled majorant is derived from those
// segment bounds, never from a sparse scan of the table.
#pragma once

#include "common.hpp"

#include <cstddef>
#include <string>
#include <vector>

namespace algoplasma {
namespace mcc {

// Linear：x-y 平面直线；LogLinear：x-log(y) 平面直线；LogLog：log(x)-log(y) 平面直线。
// 对数不能接受零或负数，对应的输入限制由 validate 检查。
enum class Interpolation : std::uint8_t { Linear = 0, LogLinear = 1, LogLog = 2 };
// 超出数据范围时：Error 报错，Zero 返回零，Clamp 保持最近端点值；不外推曲线。
enum class DomainPolicy : std::uint8_t { Error = 0, Zero = 1, Clamp = 2 };

[[nodiscard]] Interpolation interpolation_from_string(const std::string& value);
[[nodiscard]] DomainPolicy domain_policy_from_string(const std::string& value);
[[nodiscard]] const char* to_string(Interpolation value) noexcept;
[[nodiscard]] const char* to_string(DomainPolicy value) noexcept;

struct Table {
    std::string dataset_id;
    std::string path;       // package-relative path as declared in datasets.csv
    std::string x_axis;     // "energy" or "temperature"
    std::string x_unit;     // "eV" or "K"
    std::string y_unit;     // "m2", "m3/s", "m6/s"
    std::string source;
    std::string version;
    std::string license;
    std::string notes;
    Interpolation interpolation{Interpolation::Linear};
    DomainPolicy below{DomainPolicy::Error};
    DomainPolicy above{DomainPolicy::Error};
    std::vector<Real> x;
    std::vector<Real> y;

    // 直接构造 Table 的调用者也应先 validate，再 sample；后者依赖非空有序网格。
    // Throws Error when the table is malformed. `context` prefixes the message.
    void validate(const std::string& context) const;

    // Sample y(x). Sets `outside` when x is outside the declared domain and the
    // declared policy is Zero or Clamp. Throws when the policy is Error.
    [[nodiscard]] Real sample(Real x_value, bool& outside) const;

    // 这里只界定 y 的最大值；若 y 是截面，还需乘相对速率才得到速率系数上界。
    // Conservative upper bound of y on each analytic segment:
    //   Linear or (Log)Log-linear interpolation between non-negative endpoints
    //   never exceeds max(y_i, y_{i+1}) on the closed segment.
    [[nodiscard]] std::vector<Real> segment_upper_bounds() const;
    [[nodiscard]] Real upper_bound() const;

    [[nodiscard]] Real x_min() const { return x.front(); }
    [[nodiscard]] Real x_max() const { return x.back(); }
};

} // namespace mcc
} // namespace algoplasma
