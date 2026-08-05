#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"
rm -f *.o *.mod *.out
init_fortran_env
fc_compile_many \
  ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz.f90 \
  ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90 \
  ../../../E_Maxwell/E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical.f90 \
  stability_common.f90
cases=("test_stability_2d_rz_tmz:mod_E01_fdtd_2d_rz_tmz" "test_stability_2d_rz_tez:mod_E01_fdtd_2d_rz_tez" "test_stability_3d_cyl_m0:mod_E02_fdtd_3d_cylindrical" "test_stability_3d_cyl_m1:mod_E02_fdtd_3d_cylindrical")
for item in "${cases[@]}"; do
  exe="${item%%:*}"
  dep_mod="${item##*:}"
  fc_compile "${exe}.f90"
  fc_link "${exe}.out" "${dep_mod}.o" stability_common.o "${exe}.o"
done
echo "Build complete."
