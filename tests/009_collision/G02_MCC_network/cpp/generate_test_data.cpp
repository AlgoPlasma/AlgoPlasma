// SPDX-License-Identifier: Apache-2.0
// Generate synthetic model packages outside the source tree for integration
// tests and examples. These numerical fixtures are not physical cross sections.
#include "package_builder.hpp"
#include "mcc.hpp"

#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <utility>

int main(int argc, char** argv) {
    try {
        if (argc != 2 || std::string(argv[1]).empty()) {
            throw std::runtime_error("usage: g02_generate_test_data OUTPUT_DIR");
        }
        const auto root = std::filesystem::absolute(argv[1]).lexically_normal();
        const std::pair<const char*, g02test::FileMap> models[] = {
            {"demo_binary", g02test::demo_binary_package()},
            {"demo_three_body", g02test::demo_three_body_package()},
            {"collision_box_elastic", g02test::collision_box_package()},
        };
        for (const auto& [name, files] : models) {
            const auto directory = root / name;
            g02test::write_package(directory, files);
            (void)algoplasma::mcc::MccEngine::load(directory);
        }
        std::cout << "Generated 3 synthetic MCC models in " << root << '\n';
    } catch (const std::exception& error) {
        std::cerr << "g02_generate_test_data: " << error.what() << '\n';
        return 1;
    }
}
