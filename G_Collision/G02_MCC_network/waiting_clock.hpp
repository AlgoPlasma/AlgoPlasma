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
// Non-normal/overflowed products and large optical depth take the old path.
inline bool clock_definitely_outside(double u,double rate,double remaining) {
#if G02_CLOCK_REJECT && !defined(__FAST_MATH__)
    const double depth=rate*remaining;
    if (depth>=std::numeric_limits<double>::min() && depth<0.25 && u>4.0*depth) {
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
