// SPDX-License-Identifier: Apache-2.0
// Minimal dependency-free test harness.
#pragma once

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>

namespace g02test {

inline int& failure_count() {
    static int value = 0;
    return value;
}

inline int& check_count() {
    static int value = 0;
    return value;
}

inline int summary(const char* name) {
    if (failure_count() == 0) {
        std::printf("PASS %s (%d checks)\n", name, check_count());
        return 0;
    }
    std::printf("FAIL %s (%d/%d checks failed)\n", name, failure_count(), check_count());
    return 1;
}

} // namespace g02test

#define G02_CHECK(condition)                                                              \
    do {                                                                                  \
        ++::g02test::check_count();                                                       \
        if (!(condition)) {                                                               \
            ++::g02test::failure_count();                                                 \
            std::fprintf(stderr, "CHECK failed %s:%d: %s\n", __FILE__, __LINE__,          \
                         #condition);                                                     \
        }                                                                                 \
    } while (false)

#define G02_REQUIRE(condition)                                                            \
    do {                                                                                  \
        ++::g02test::check_count();                                                       \
        if (!(condition)) {                                                               \
            ++::g02test::failure_count();                                                 \
            std::fprintf(stderr, "REQUIRE failed %s:%d: %s\n", __FILE__, __LINE__,        \
                         #condition);                                                     \
            return 1;                                                                     \
        }                                                                                 \
    } while (false)

#define G02_CHECK_NEAR(actual, expected, tolerance)                                       \
    do {                                                                                  \
        ++::g02test::check_count();                                                       \
        const double g02_actual = static_cast<double>(actual);                            \
        const double g02_expected = static_cast<double>(expected);                        \
        const double g02_tolerance = static_cast<double>(tolerance);                      \
        if (!(std::fabs(g02_actual - g02_expected) <= g02_tolerance)) {                   \
            ++::g02test::failure_count();                                                 \
            std::fprintf(stderr, "CHECK_NEAR failed %s:%d: %.17g vs %.17g (tol %.3g)\n",  \
                         __FILE__, __LINE__, g02_actual, g02_expected, g02_tolerance);    \
        }                                                                                 \
    } while (false)

#define G02_CHECK_THROWS(expression)                                                      \
    do {                                                                                  \
        ++::g02test::check_count();                                                       \
        bool g02_thrown = false;                                                          \
        try {                                                                             \
            (void)(expression);                                                           \
        } catch (const std::exception&) {                                                 \
            g02_thrown = true;                                                            \
        } catch (...) {                                                                   \
            g02_thrown = true;                                                            \
        }                                                                                 \
        if (!g02_thrown) {                                                                \
            ++::g02test::failure_count();                                                 \
            std::fprintf(stderr, "CHECK_THROWS failed %s:%d: %s\n", __FILE__, __LINE__,   \
                         #expression);                                                    \
        }                                                                                 \
    } while (false)

#define G02_CHECK_MESSAGE_CONTAINS(expression, needle)                                    \
    do {                                                                                  \
        ++::g02test::check_count();                                                       \
        std::string g02_message;                                                          \
        bool g02_thrown = false;                                                          \
        try {                                                                             \
            (void)(expression);                                                           \
        } catch (const std::exception& g02_error) {                                       \
            g02_message = g02_error.what();                                               \
            g02_thrown = true;                                                            \
        }                                                                                 \
        const std::string g02_needle = (needle);                                          \
        if (!g02_thrown || g02_message.find(g02_needle) == std::string::npos) {           \
            ++::g02test::failure_count();                                                 \
            std::fprintf(stderr,                                                          \
                         "CHECK_MESSAGE_CONTAINS failed %s:%d: expected '%s' in '%s'\n",  \
                         __FILE__, __LINE__, g02_needle.c_str(), g02_message.c_str());    \
        }                                                                                 \
    } while (false)
