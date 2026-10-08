# SPDX-License-Identifier: Apache-2.0
# G02 library build recipe. Functional sources remain in G_Collision/G02_MCC_network.
# The tests directory owns build configuration, examples and synthetic data.
include_guard(GLOBAL)

get_filename_component(G02_MCC_REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../.." ABSOLUTE)
set(G02_MCC_SOURCE_DIR "${G02_MCC_REPO_ROOT}/G_Collision/G02_MCC_network")

option(G02_MCC_ENABLE_SANITIZERS "Build with AddressSanitizer and UndefinedBehaviorSanitizer" OFF)
option(G02_MCC_ENABLE_OPENMP "Build the optional OpenMP batch backend" OFF)
option(G02_MCC_ENABLE_MPI "Build the optional MPI distributed adapter" OFF)

# Define compiler settings for the library and its callers in this test project.
if(NOT COMMAND g02_mcc_configure_cxx)
    function(g02_mcc_configure_cxx target)
        if(MSVC)
            target_compile_options(${target} PRIVATE /W4)
        else()
            target_compile_options(${target} PRIVATE -Wall -Wextra -Wpedantic -Wconversion)
        endif()
        if(G02_MCC_ENABLE_SANITIZERS AND NOT MSVC)
            target_compile_options(${target} PRIVATE -fsanitize=address,undefined
                                                      -fno-omit-frame-pointer)
            target_link_options(${target} PRIVATE -fsanitize=address,undefined)
        endif()
    endfunction()
endif()

set(G02_MCC_CORE_SOURCES
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_csv.cpp"
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_table.cpp"
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_model.cpp"
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_compile.cpp"
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_kinematics.cpp"
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_engine.cpp"
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_batch.cpp")

add_library(g02_mcc STATIC ${G02_MCC_CORE_SOURCES})
add_library(AlgoPlasma::G02_MCC ALIAS g02_mcc)
set_target_properties(g02_mcc PROPERTIES EXPORT_NAME G02_MCC)

target_include_directories(g02_mcc
    PUBLIC
        $<BUILD_INTERFACE:${G02_MCC_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include/G02_MCC_network>)
target_compile_features(g02_mcc PUBLIC cxx_std_20)
g02_mcc_configure_cxx(g02_mcc)
if(G02_MCC_ENABLE_OPENMP)
    find_package(OpenMP REQUIRED COMPONENTS CXX)
    target_link_libraries(g02_mcc PUBLIC OpenMP::OpenMP_CXX)
endif()

if(G02_MCC_ENABLE_MPI)
    find_package(MPI REQUIRED COMPONENTS CXX)
    add_library(g02_mcc_mpi STATIC "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_mpi.cpp")
    add_library(AlgoPlasma::G02_MCC_MPI ALIAS g02_mcc_mpi)
    set_target_properties(g02_mcc_mpi PROPERTIES EXPORT_NAME G02_MCC_MPI)
    target_include_directories(g02_mcc_mpi PUBLIC
        $<BUILD_INTERFACE:${G02_MCC_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include/G02_MCC_network>)
    target_link_libraries(g02_mcc_mpi PUBLIC g02_mcc MPI::MPI_CXX)
    target_compile_features(g02_mcc_mpi PUBLIC cxx_std_20)
    g02_mcc_configure_cxx(g02_mcc_mpi)
endif()

install(TARGETS g02_mcc EXPORT G02MCCTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin)
if(G02_MCC_ENABLE_MPI)
    install(TARGETS g02_mcc_mpi EXPORT G02MCCTargets
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin)
endif()
set(G02_MCC_PUBLIC_HEADERS
    "${G02_MCC_SOURCE_DIR}/batch.hpp"
    "${G02_MCC_SOURCE_DIR}/common.hpp"
    "${G02_MCC_SOURCE_DIR}/compile.hpp"
    "${G02_MCC_SOURCE_DIR}/csv.hpp"
    "${G02_MCC_SOURCE_DIR}/engine.hpp"
    "${G02_MCC_SOURCE_DIR}/kinematics.hpp"
    "${G02_MCC_SOURCE_DIR}/mcc.hpp"
    "${G02_MCC_SOURCE_DIR}/model.hpp"
    "${G02_MCC_SOURCE_DIR}/mpi.hpp"
    "${G02_MCC_SOURCE_DIR}/rng.hpp"
    "${G02_MCC_SOURCE_DIR}/table.hpp"
)
install(FILES ${G02_MCC_PUBLIC_HEADERS} DESTINATION include/G02_MCC_network)

include(CMakePackageConfigHelpers)
set(G02_MCC_CONFIG_DIR "lib/cmake/G02_MCC_network")
configure_package_config_file(
    "${CMAKE_CURRENT_LIST_DIR}/G02_MCC_networkConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/G02_MCC_networkConfig.cmake"
    INSTALL_DESTINATION "${G02_MCC_CONFIG_DIR}")
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/G02_MCC_networkConfigVersion.cmake"
    VERSION 1.0.0 COMPATIBILITY SameMajorVersion)
install(EXPORT G02MCCTargets FILE G02MCCTargets.cmake
    NAMESPACE AlgoPlasma:: DESTINATION "${G02_MCC_CONFIG_DIR}")
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/G02_MCC_networkConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/G02_MCC_networkConfigVersion.cmake"
    DESTINATION "${G02_MCC_CONFIG_DIR}")
