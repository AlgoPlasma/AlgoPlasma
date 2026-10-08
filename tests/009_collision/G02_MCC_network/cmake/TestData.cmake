# SPDX-License-Identifier: Apache-2.0
# CTest builds its synthetic model packages in the binary tree before dependents
# run. Direct example runs can invoke g02_generate_test_data OUTPUT_DIR too.
include_guard(GLOBAL)
get_filename_component(G02_MCC_FIXTURE_TEST_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(G02_MCC_GENERATED_MODELS_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated_models")
add_executable(g02_generate_test_data
    "${G02_MCC_FIXTURE_TEST_DIR}/cpp/generate_test_data.cpp")
target_link_libraries(g02_generate_test_data PRIVATE AlgoPlasma::G02_MCC)
if(COMMAND g02_mcc_configure_cxx)
    g02_mcc_configure_cxx(g02_generate_test_data)
endif()
add_test(NAME G02_MCC_generate_test_data
    COMMAND g02_generate_test_data "${G02_MCC_GENERATED_MODELS_DIR}")
set_tests_properties(G02_MCC_generate_test_data PROPERTIES FIXTURES_SETUP G02_MCC_models)
