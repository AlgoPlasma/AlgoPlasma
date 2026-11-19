// SPDX-License-Identifier: Apache-2.0
#include "test_support.hpp"
#include <utility>

int main(int argc, char** argv) {
    const std::pair<const char*, void(*)()> groups[]{
        {"models", test::models}, {"scattering", test::scattering},
        {"random", test::random_sampling}, {"geometry", test::geometry},
        {"conservation", test::conservation}, {"schedules", test::schedules},
        {"replay", test::replay}, {"errors", test::errors}};
    if (argc != 2) {
        std::cerr << "usage: dsmc_tests models|scattering|random|geometry|conservation|schedules|replay|errors\n";
        return 2;
    }
    for (const auto& [name, run] : groups) {
        if (std::string(argv[1]) == name) {
            try {
                run();
                std::cout << "PASS: " << name << '\n';
                return 0;
            } catch (const std::exception& error) {
                std::cerr << "FAIL: " << name << ": " << error.what() << '\n';
                return 1;
            }
        }
    }
    std::cerr << "unknown test group: " << argv[1] << '\n';
    return 2;
}
