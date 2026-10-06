cmake_minimum_required(VERSION 3.20)
project(g02_mcc_host_pic LANGUAGES CXX)

find_package(G02_MCC_network CONFIG REQUIRED)
add_executable(g02_mcc_host_pic main.cpp)
target_link_libraries(g02_mcc_host_pic PRIVATE AlgoPlasma::G02_MCC)
