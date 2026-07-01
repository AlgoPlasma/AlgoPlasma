#!/usr/bin/env bash
set -euo pipefail

./make.sh

for exe in test_3d_cartesian_single_step test_2d_rz_tmz_single_step test_2d_rz_tez_single_step test_3d_cyl_m0_single_step test_3d_cyl_m1_single_step; do
  "./${exe}.out" | tee "${exe}.log"
done
