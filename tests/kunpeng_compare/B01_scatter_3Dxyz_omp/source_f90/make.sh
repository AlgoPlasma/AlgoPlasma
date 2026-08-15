#!/bin/bash
./clean.sh
mkdir -p build
cd build
# gfortran -O3 -fdefault-real-8 -fopenmp xxxx.f90
gfortran -cpp -O3 -fdefault-real-8 -fopenmp ../main.f90
