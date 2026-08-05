#!/usr/bin/env bash
set -euo pipefail

./make.sh

for exe in test_mms_3d_cartesian_convergence test_mms_2d_rz_tmz_convergence test_mms_2d_rz_tez_convergence test_mms_3d_cyl_m0_convergence test_mms_3d_cyl_m1_convergence; do
  "./${exe}.out" | tee "${exe}.log"
done
