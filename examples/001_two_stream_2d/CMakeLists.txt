cmake_minimum_required(VERSION 3.20)
project(algoplasma_two_stream LANGUAGES C Fortran)

find_package(MPI REQUIRED COMPONENTS Fortran)

# User configuration: set this to the local HYPRE installation prefix.
set(HYPRE_ROOT "/opt/hypre-3.1.0" CACHE PATH "HYPRE installation prefix")
find_package(HYPRE 3.1 CONFIG REQUIRED
    PATHS
        "${HYPRE_ROOT}/lib/cmake/HYPRE"
        "${HYPRE_ROOT}/lib64/cmake/HYPRE"
    NO_DEFAULT_PATH)

get_filename_component(DEFAULT_ALGOPLASMA_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(ALGOPLASMA_ROOT "${DEFAULT_ALGOPLASMA_ROOT}" CACHE PATH "AlgoPlasma source root")

set(CMAKE_Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/mod")

set(ALGOPLASMA_SOURCES
    ${ALGOPLASMA_ROOT}/I_Initializer/I01_par_distribute/mod_I01_par_distribute.f90
    ${ALGOPLASMA_ROOT}/A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90
    ${ALGOPLASMA_ROOT}/B_Scatter/B01_scatter_3Dxyz/mod_B01_scatter_3Dxyz.f90
    ${ALGOPLASMA_ROOT}/C_Gather/C01_gather_3Dxyz/mod_C01_gather_3Dxyz.f90
    ${ALGOPLASMA_ROOT}/D_Poisson/D02_hypre_3Dxyz_bc/mod_D02_hypre_3Dxyz_bc.f90
    ${ALGOPLASMA_ROOT}/D_Poisson/D05_phi1d_to_phi3d/mod_D05_phi1d_to_phi3d.f90
    ${ALGOPLASMA_ROOT}/D_Poisson/D06_phi_to_E/mod_D06_phi_to_E.f90
    ${ALGOPLASMA_ROOT}/F_IO/F02_par_output/mod_F02_par_output.f90
    ${ALGOPLASMA_ROOT}/F_IO/F04_field_output/mod_F04_field_output.f90
    ${ALGOPLASMA_ROOT}/D_Poisson/D02_hypre_3Dxyz_bc/fun_D02_hypre_3Dxyz_bc.c)

add_library(algoplasma_two_stream_modules ${ALGOPLASMA_SOURCES})

target_include_directories(algoplasma_two_stream_modules PUBLIC
    ${CMAKE_Fortran_MODULE_DIRECTORY}
    ${ALGOPLASMA_ROOT}/I_Initializer/I01_par_distribute
    ${ALGOPLASMA_ROOT}/A_Pusher/A01_Boris_3Dxyz
    ${ALGOPLASMA_ROOT}/B_Scatter/B01_scatter_3Dxyz
    ${ALGOPLASMA_ROOT}/C_Gather/C01_gather_3Dxyz
    ${ALGOPLASMA_ROOT}/D_Poisson/D02_hypre_3Dxyz_bc
    ${ALGOPLASMA_ROOT}/D_Poisson/D05_phi1d_to_phi3d
    ${ALGOPLASMA_ROOT}/D_Poisson/D06_phi_to_E
    ${ALGOPLASMA_ROOT}/F_IO/F02_par_output
    ${ALGOPLASMA_ROOT}/F_IO/F04_field_output)

target_compile_options(algoplasma_two_stream_modules PRIVATE
    $<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-cpp;-DUSE_HDF5=0;-O3;-fdefault-real-8>)
target_link_libraries(algoplasma_two_stream_modules PUBLIC
    MPI::MPI_Fortran HYPRE::HYPRE)

add_executable(two_stream_2d
    src/case_parameters.f90
    src/two_stream_case.f90
    src/main.f90)
target_compile_options(two_stream_2d PRIVATE
    $<$<COMPILE_LANG_AND_ID:Fortran,GNU>:-cpp;-DUSE_HDF5=0;-O3;-fdefault-real-8>)
target_link_libraries(two_stream_2d PRIVATE algoplasma_two_stream_modules)

