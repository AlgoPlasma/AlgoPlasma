cmake_minimum_required(VERSION 3.20)
project(g02_mcc_mpi_collision_box LANGUAGES CXX)

find_package(G02_MCC_network CONFIG REQUIRED)
add_executable(mpi_collision_box main.cpp)
target_link_libraries(mpi_collision_box PRIVATE AlgoPlasma::G02_MCC_MPI)
