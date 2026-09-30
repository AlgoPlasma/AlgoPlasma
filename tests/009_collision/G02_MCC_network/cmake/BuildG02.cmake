# SPDX-License-Identifier: Apache-2.0
# G02 library build recipe. Functional sources remain in G_Collision/G02_MCC_network.
# The tests directory owns build configuration, examples and synthetic data.
include_guard(GLOBAL)

get_filename_component(G02_MCC_REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../.." ABSOLUTE)
set(G02_MCC_SOURCE_DIR "${G02_MCC_REPO_ROOT}/G_Collision/G02_MCC_network")

option(G02_MCC_ENABLE_FORTRAN "Build the Fortran ISO_C_BINDING adapter" ON)
option(G02_MCC_ENABLE_SANITIZERS "Build with AddressSanitizer and UndefinedBehaviorSanitizer" OFF)
option(G02_MCC_ENABLE_OPENMP "Build the optional OpenMP batch backend" OFF)
option(G02_MCC_ENABLE_MPI "Build the optional MPI distributed adapter" OFF)

if(G02_MCC_ENABLE_FORTRAN AND NOT CMAKE_Fortran_COMPILER_LOADED)
    enable_language(Fortran)
endif()

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

if(NOT COMMAND g02_mcc_configure_fortran)
    function(g02_mcc_configure_fortran target)
        if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
            target_compile_options(${target} PRIVATE -Wall -Wextra -fcheck=all)
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
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_batch.cpp"
    "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_c_api.cpp")

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
    add_library(g02_mcc_mpi STATIC "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_mpi.cpp" "${G02_MCC_SOURCE_DIR}/fun_G02_mcc_mpi_c_api.cpp")
    add_library(AlgoPlasma::G02_MCC_MPI ALIAS g02_mcc_mpi)
    set_target_properties(g02_mcc_mpi PROPERTIES EXPORT_NAME G02_MCC_MPI)
    target_include_directories(g02_mcc_mpi PUBLIC
        $<BUILD_INTERFACE:${G02_MCC_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include/G02_MCC_network>)
    target_link_libraries(g02_mcc_mpi PUBLIC g02_mcc MPI::MPI_CXX)
    target_compile_features(g02_mcc_mpi PUBLIC cxx_std_20)
    g02_mcc_configure_cxx(g02_mcc_mpi)
endif()

if(G02_MCC_ENABLE_FORTRAN)
    set(G02_MCC_FORTRAN_MODULE_DIR "${CMAKE_CURRENT_BINARY_DIR}/fortran_modules")
    add_library(g02_mcc_fortran STATIC "${G02_MCC_SOURCE_DIR}/fortran_interface/mod_G02_MCC_network.f90")
    add_library(AlgoPlasma::G02_MCC_Fortran ALIAS g02_mcc_fortran)
    set_target_properties(g02_mcc_fortran PROPERTIES EXPORT_NAME G02_MCC_Fortran)
    set_target_properties(g02_mcc_fortran PROPERTIES
        Fortran_MODULE_DIRECTORY "${G02_MCC_FORTRAN_MODULE_DIR}")
    target_include_directories(g02_mcc_fortran
        PRIVATE "${G02_MCC_SOURCE_DIR}/fortran_interface"
        PUBLIC
            $<BUILD_INTERFACE:${G02_MCC_FORTRAN_MODULE_DIR}>
            $<INSTALL_INTERFACE:include>)
    target_link_libraries(g02_mcc_fortran PUBLIC g02_mcc)
    g02_mcc_configure_fortran(g02_mcc_fortran)
endif()

if(G02_MCC_ENABLE_FORTRAN AND G02_MCC_ENABLE_MPI)
    find_package(MPI REQUIRED COMPONENTS Fortran)
    set(G02_MCC_FORTRAN_MPI_MODULE_DIR "${CMAKE_CURRENT_BINARY_DIR}/fortran_mpi_modules")
    add_library(g02_mcc_fortran_mpi STATIC "${G02_MCC_SOURCE_DIR}/fortran_interface/mod_G02_MCC_network_mpi.f90")
    add_library(AlgoPlasma::G02_MCC_Fortran_MPI ALIAS g02_mcc_fortran_mpi)
    set_target_properties(g02_mcc_fortran_mpi PROPERTIES
        EXPORT_NAME G02_MCC_Fortran_MPI
        Fortran_MODULE_DIRECTORY "${G02_MCC_FORTRAN_MPI_MODULE_DIR}")
    target_include_directories(g02_mcc_fortran_mpi
        PRIVATE "${G02_MCC_SOURCE_DIR}/fortran_interface"
        PUBLIC
        $<BUILD_INTERFACE:${G02_MCC_FORTRAN_MPI_MODULE_DIR}>
        $<INSTALL_INTERFACE:include>)
    target_link_libraries(g02_mcc_fortran_mpi PUBLIC
        g02_mcc_fortran g02_mcc_mpi MPI::MPI_Fortran)
    g02_mcc_configure_fortran(g02_mcc_fortran_mpi)
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
    "${G02_MCC_SOURCE_DIR}/c_api.h"
    "${G02_MCC_SOURCE_DIR}/common.hpp"
    "${G02_MCC_SOURCE_DIR}/compile.hpp"
    "${G02_MCC_SOURCE_DIR}/csv.hpp"
    "${G02_MCC_SOURCE_DIR}/engine.hpp"
    "${G02_MCC_SOURCE_DIR}/kinematics.hpp"
    "${G02_MCC_SOURCE_DIR}/mcc.hpp"
    "${G02_MCC_SOURCE_DIR}/model.hpp"
    "${G02_MCC_SOURCE_DIR}/mpi.hpp"
    "${G02_MCC_SOURCE_DIR}/mpi_c_api.h"
    "${G02_MCC_SOURCE_DIR}/rng.hpp"
    "${G02_MCC_SOURCE_DIR}/table.hpp"
)
install(FILES ${G02_MCC_PUBLIC_HEADERS} DESTINATION include/G02_MCC_network)

if(G02_MCC_ENABLE_FORTRAN)
    install(TARGETS g02_mcc_fortran EXPORT G02MCCTargets
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin)
    # Install the generated GNU Fortran module file next to the headers.
    install(DIRECTORY "${G02_MCC_FORTRAN_MODULE_DIR}/" DESTINATION include
        FILES_MATCHING PATTERN "*.mod")
endif()
if(G02_MCC_ENABLE_FORTRAN AND G02_MCC_ENABLE_MPI)
    install(TARGETS g02_mcc_fortran_mpi EXPORT G02MCCTargets
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin)
    install(DIRECTORY "${G02_MCC_FORTRAN_MPI_MODULE_DIR}/" DESTINATION include
        FILES_MATCHING PATTERN "*.mod")
endif()

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
