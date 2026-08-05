#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../common.sh"

rm -f *.o *.mod *.out *.log *.pgm

init_fortran_env

fc_compile_many \
  ../../../E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian.f90 \
  ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz.f90 \
  ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90 \
  ../../../E_Maxwell/E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical.f90 \
  test_single_step_utils.f90

cases=(
  "test_3d_cartesian_single_step:mod_E03_fdtd_3d_cartesian"
  "test_2d_rz_tmz_single_step:mod_E01_fdtd_2d_rz_tmz"
  "test_2d_rz_tez_single_step:mod_E01_fdtd_2d_rz_tez"
  "test_3d_cyl_m0_single_step:mod_E02_fdtd_3d_cylindrical"
  "test_3d_cyl_m1_single_step:mod_E02_fdtd_3d_cylindrical"
)

for item in "${cases[@]}"; do
  exe="${item%%:*}"
  dep_mod="${item##*:}"
  fc_compile "${exe}.f90"
  fc_link "${exe}.out" test_single_step_utils.o "${dep_mod}.o" "${exe}.o"
done

echo "Build complete."
