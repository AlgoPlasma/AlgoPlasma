// SPDX-License-Identifier: Apache-2.0
#include "engine.hpp"

#include <exception>
#include <iostream>

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "Usage: g02_validate_model MODEL_DIRECTORY\n";
        return 2;
    }
    try {
        const auto engine = algoplasma::mcc::MccEngine::load(argv[1]);
        const auto& model = engine.model();
        if (model.species.all().empty() || model.reactions.empty()) {
            std::cerr << "FAIL: provide species and at least one enabled reaction; "
                         "a blank template is not a usable collision model.\n";
            return 1;
        }
        std::cout << "PASS: loaded and compiled " << model.name
                  << "; species=" << model.species.all().size()
                  << "; enabled_reactions=" << model.reactions.size()
                  << "\nThis checks model structure and supported constraints, not scientific validity.\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
