// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <cmath>
#include <limits>
#include <stdexcept>
#ifndef G02_CLOCK_REJECT
#define G02_CLOCK_REJECT 1
#endif
#ifndef G02_CLOCK_AUDIT
#define G02_CLOCK_AUDIT 0
#endif
namespace algoplasma { namespace mcc {
// Conservative rejection ONLY. Near the decision boundary the old expression
// and comparison execute unchanged. Tested target: IEEE binary64, glibc libm.
// -log(1-u) >= u. A factor-four margin deliberately avoids rounding boundaries.
// Extreme operands take the original path before any speculative multiplication.
inline bool clock_definitely_outside(double u,double rate,double remaining) {
#if G02_CLOCK_REJECT && !defined(__FAST_MATH__)
    // Within these bounds the product is a normal, finite binary64 value.
    // Outside them, even forming the product can raise a new FP exception.
    constexpr double lo = 0x1p-511, hi = 0x1p511;
    if (!(rate >= lo && rate <= hi && remaining >= lo && remaining <= hi)) return false;
    const double depth=rate*remaining;
    if (depth<0.25 && u>4.0*depth) {
#if G02_CLOCK_AUDIT
        if (-std::log1p(-u)/rate <= remaining)
            throw std::runtime_error("clock fast-reject changed an event decision");
#endif
        return true;
    }
#endif
    return false;
}
}}
