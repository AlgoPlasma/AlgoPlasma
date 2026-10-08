cmake_minimum_required(VERSION 3.20)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(g02_mcc_collision_box LANGUAGES CXX)
    find_package(G02_MCC_network CONFIG REQUIRED)
endif()

add_executable(collision_box main.cpp)
target_link_libraries(collision_box PRIVATE AlgoPlasma::G02_MCC)
target_include_directories(collision_box PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../../cpp")
if(COMMAND g02_mcc_configure_cxx)
    g02_mcc_configure_cxx(collision_box)
endif()
