#!/usr/bin/env bash
set -euo pipefail

rm -f *.o *.mod *.out

gfortran -cpp -O2 -fdefault-real-8 -fopenmp -c ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz.f90
gfortran -cpp -O2 -fdefault-real-8 -fopenmp -c ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90
gfortran -cpp -O2 -fdefault-real-8 -fopenmp -c ../../../E_Maxwell/E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical.f90

gfortran -cpp -O2 -fdefault-real-8 -fopenmp -c geom_special_common.f90
gfortran -cpp -O2 -fdefault-real-8 -fopenmp -c geom_special_fdtd_support.f90
gfortran -cpp -O2 -fdefault-real-8 -fopenmp -c test_geom_m0_equivalence.f90

gfortran -O2 -fdefault-real-8 -fopenmp -o test_geom_m0_equivalence.out \
  mod_E01_fdtd_2d_rz_tmz.o mod_E01_fdtd_2d_rz_tez.o mod_E02_fdtd_3d_cylindrical.o \
  geom_special_common.o geom_special_fdtd_support.o test_geom_m0_equivalence.o

echo "Build complete."
