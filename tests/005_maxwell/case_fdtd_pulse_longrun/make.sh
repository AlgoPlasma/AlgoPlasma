#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../common.sh"

rm -f *.o *.mod *.out

init_fortran_env

fc_compile_many \
  ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz.f90 \
  ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90 \
  ../../../E_Maxwell/E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical.f90 \
  ../../../E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian.f90 \
  pulse_common.f90

cases=(
  "test_pulse_2d_rz_tmz:mod_E01_fdtd_2d_rz_tmz"
  "test_pulse_2d_rz_tez:mod_E01_fdtd_2d_rz_tez"
  "test_pulse_3d_cyl_m0:mod_E02_fdtd_3d_cylindrical"
  "test_pulse_3d_cyl_m1:mod_E02_fdtd_3d_cylindrical"
  "test_pulse_3d_cartesian:mod_E03_fdtd_3d_cartesian"
)

for item in "${cases[@]}"; do
  exe="${item%%:*}"
  dep_mod="${item##*:}"
  fc_compile "${exe}.f90"
  fc_link "${exe}.out" "${dep_mod}.o" pulse_common.o "${exe}.o"
done

echo "Build complete."
