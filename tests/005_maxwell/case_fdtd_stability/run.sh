#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../common.sh"

NSTEPS="${1:-20000}"
MONITOR_EVERY="${2:-100}"

./make.sh

mkdir -p logs
rm -f logs/*.log stability_summary.csv

echo "case_name,CFL,nsteps,final_energy_ratio,max_abs_E_final,max_abs_H_final,result" > stability_summary.csv

for item in \
  "test_stability_2d_rz_tmz:2d_rz_tmz" \
  "test_stability_2d_rz_tez:2d_rz_tez" \
  "test_stability_3d_cyl_m0:3d_cyl_m0" \
  "test_stability_3d_cyl_m1:3d_cyl_m1"
do
  exe="${item%%:*}"
  log_name="${item##*:}"
  fallback="${log_name},NA,${NSTEPS},NA,NA,NA,unstable"
  run_case_and_capture_summary \
    "${exe}" \
    "logs/${log_name}.log" \
    stability_summary.csv \
    "${fallback}" \
    "${NSTEPS}" "${MONITOR_EVERY}"
done

echo "Wrote logs under logs/ and summary file stability_summary.csv"
