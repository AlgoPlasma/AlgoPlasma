# SPDX-License-Identifier: Apache-2.0
# Build G02 from the source-only module directory, with optional tests/examples.
cmake_minimum_required(VERSION 3.20)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(G02_MCC_network_tests VERSION 1.0.0 LANGUAGES CXX)
endif()

option(G02_MCC_BUILD_TESTS "Build G02 regression tests and validation examples" ON)
set(G02_MCC_TEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/BuildG02.cmake")

if(NOT G02_MCC_BUILD_TESTS)
    return()
endif()
enable_testing()

add_executable(g02_validate_model tools/validate_model.cpp)
target_link_libraries(g02_validate_model PRIVATE g02_mcc)
g02_mcc_configure_cxx(g02_validate_model)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/TestData.cmake")
set(G02_MCC_DEMO_BINARY "${G02_MCC_GENERATED_MODELS_DIR}/demo_binary")
set(G02_MCC_DEMO_THREE_BODY "${G02_MCC_GENERATED_MODELS_DIR}/demo_three_body")
set(G02_MCC_COLLISION_BOX_MODEL "${G02_MCC_GENERATED_MODELS_DIR}/collision_box_elastic")

add_executable(test_schema cpp/test_schema.cpp)
target_link_libraries(test_schema PRIVATE g02_mcc)
g02_mcc_configure_cxx(test_schema)
add_test(NAME G02_MCC_schema COMMAND test_schema)

add_executable(test_interpolation cpp/test_interpolation.cpp)
target_link_libraries(test_interpolation PRIVATE g02_mcc)
g02_mcc_configure_cxx(test_interpolation)
add_test(NAME G02_MCC_interpolation COMMAND test_interpolation)

add_executable(test_c01 cpp/test_c01.cpp)
target_link_libraries(test_c01 PRIVATE g02_mcc)
g02_mcc_configure_cxx(test_c01)
add_test(NAME G02_MCC_c01 COMMAND test_c01)

add_executable(test_batch cpp/test_batch.cpp)
target_link_libraries(test_batch PRIVATE g02_mcc)
g02_mcc_configure_cxx(test_batch)
add_test(NAME G02_MCC_batch COMMAND test_batch "${G02_MCC_DEMO_BINARY}")

add_executable(test_sampler cpp/test_sampler.cpp)
target_link_libraries(test_sampler PRIVATE g02_mcc)
g02_mcc_configure_cxx(test_sampler)
add_test(NAME G02_MCC_sampler COMMAND test_sampler)

add_executable(bench_batch cpp/bench_batch.cpp)
target_link_libraries(bench_batch PRIVATE g02_mcc)
g02_mcc_configure_cxx(bench_batch)

add_subdirectory("${G02_MCC_TEST_DIR}/examples/collision_box"
    "${CMAKE_CURRENT_BINARY_DIR}/collision_box")
add_test(NAME G02_MCC_collision_box_tau_20
    COMMAND collision_box --model "${G02_MCC_COLLISION_BOX_MODEL}" --particles 3000 --steps 200 --dt 1e-7)
add_test(NAME G02_MCC_collision_box_tau_20_coarse
    COMMAND collision_box --model "${G02_MCC_COLLISION_BOX_MODEL}" --particles 3000 --steps 10 --dt 2e-6)
add_test(NAME G02_MCC_collision_box_tau_20_medium
    COMMAND collision_box --model "${G02_MCC_COLLISION_BOX_MODEL}" --particles 3000 --steps 40 --dt 5e-7)
add_test(NAME G02_MCC_collision_box_zero_density
    COMMAND collision_box --model "${G02_MCC_COLLISION_BOX_MODEL}" --particles 1000 --steps 5 --density 0)
add_test(NAME G02_MCC_collision_box_zero_dt
    COMMAND collision_box --model "${G02_MCC_COLLISION_BOX_MODEL}" --particles 1000 --steps 5 --dt 0)
add_test(NAME G02_MCC_collision_box_equilibrium
    COMMAND collision_box --model "${G02_MCC_COLLISION_BOX_MODEL}" --particles 3000 --steps 20 --dt 1e-6
                          --initial-temperature 300 --drift-x 0)
add_test(NAME G02_MCC_collision_box_alias
    COMMAND collision_box --model "${G02_MCC_COLLISION_BOX_MODEL}" --particles 3000 --steps 20 --dt 1e-6 --sampler alias)
if(G02_MCC_ENABLE_OPENMP)
    add_test(NAME G02_MCC_collision_box_serial_openmp
        COMMAND collision_box --model "${G02_MCC_COLLISION_BOX_MODEL}" --particles 3000 --steps 20 --dt 1e-6
                              --threads 4 --compare-backends)
endif()

if(G02_MCC_ENABLE_MPI)
    add_executable(test_mpi cpp/test_mpi.cpp)
    target_link_libraries(test_mpi PRIVATE g02_mcc_mpi)
    g02_mcc_configure_cxx(test_mpi)
    foreach(ranks IN ITEMS 1 2 4)
        add_test(NAME G02_MCC_mpi_${ranks}
            COMMAND ${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${ranks}
                    ${MPIEXEC_PREFLAGS} $<TARGET_FILE:test_mpi>
                    "${G02_MCC_DEMO_BINARY}" ${MPIEXEC_POSTFLAGS})
    endforeach()
    add_executable(mpi_collision_box
        "${G02_MCC_TEST_DIR}/examples/mpi_collision_box/main.cpp")
    target_link_libraries(mpi_collision_box PRIVATE g02_mcc_mpi)
    g02_mcc_configure_cxx(mpi_collision_box)
endif()

add_executable(test_algorithms cpp/test_algorithms.cpp)
target_link_libraries(test_algorithms PRIVATE g02_mcc)
g02_mcc_configure_cxx(test_algorithms)
add_test(NAME G02_MCC_algorithms
    COMMAND test_algorithms "${G02_MCC_DEMO_BINARY}" "${G02_MCC_DEMO_THREE_BODY}")

set_tests_properties(G02_MCC_batch G02_MCC_algorithms
    G02_MCC_collision_box_tau_20 G02_MCC_collision_box_tau_20_coarse
    G02_MCC_collision_box_tau_20_medium G02_MCC_collision_box_zero_density
    G02_MCC_collision_box_zero_dt G02_MCC_collision_box_equilibrium
    G02_MCC_collision_box_alias
    PROPERTIES FIXTURES_REQUIRED G02_MCC_models)
if(G02_MCC_ENABLE_OPENMP)
    set_tests_properties(G02_MCC_collision_box_serial_openmp
        PROPERTIES FIXTURES_REQUIRED G02_MCC_models)
endif()
if(G02_MCC_ENABLE_MPI)
    foreach(ranks IN ITEMS 1 2 4)
        set_tests_properties(G02_MCC_mpi_${ranks}
            PROPERTIES FIXTURES_REQUIRED G02_MCC_models)
    endforeach()
endif()
add_test(NAME G02_MCC_collision_box_default_model
    COMMAND collision_box --particles 1000 --steps 5 --dt 0)
add_test(NAME G02_MCC_collision_box_missing_model
    COMMAND collision_box --model "${G02_MCC_GENERATED_MODELS_DIR}/missing_model"
                          --particles 1000 --steps 5 --dt 0)
set_tests_properties(G02_MCC_collision_box_missing_model PROPERTIES WILL_FAIL TRUE)
