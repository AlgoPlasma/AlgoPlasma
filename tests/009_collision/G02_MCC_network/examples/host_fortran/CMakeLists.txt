cmake_minimum_required(VERSION 3.20)
project(g02_mcc_host_fortran LANGUAGES CXX Fortran)

find_package(G02_MCC_network CONFIG REQUIRED)
add_executable(g02_mcc_host_fortran main.f90)
target_link_libraries(g02_mcc_host_fortran PRIVATE AlgoPlasma::G02_MCC_Fortran)
