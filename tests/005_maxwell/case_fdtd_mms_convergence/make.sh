#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../common.sh"

rm -f *.o *.mod *.out *.log *.txt

init_fortran_env

fc_compile_many \
  ../../../E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian.f90 \
  ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz.f90 \
  ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90 \
  ../../../E_Maxwell/E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical.f90 \
  mms_exact_sources.f90 \
  mms_convergence_utils.f90

cases=(
  "test_mms_3d_cartesian_convergence:mod_E03_fdtd_3d_cartesian"
  "test_mms_2d_rz_tmz_convergence:mod_E01_fdtd_2d_rz_tmz"
  "test_mms_2d_rz_tez_convergence:mod_E01_fdtd_2d_rz_tez"
  "test_mms_3d_cyl_m0_convergence:mod_E02_fdtd_3d_cylindrical"
  "test_mms_3d_cyl_m1_convergence:mod_E02_fdtd_3d_cylindrical"
)

for item in "${cases[@]}"; do
  exe="${item%%:*}"
  dep_mod="${item##*:}"
  fc_compile "${exe}.f90"
  fc_link "${exe}.out" mms_exact_sources.o mms_convergence_utils.o "${dep_mod}.o" "${exe}.o"
done

echo "Build complete."
