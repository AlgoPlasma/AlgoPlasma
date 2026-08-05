#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../common.sh"

NTOTAL="${1:-20000}"
MONITOR_EVERY="${2:-100}"
NPULSE="${3:-60}"
PULSE_AMP="${4:-1e-4}"

./make.sh

mkdir -p logs
rm -f logs/*.log pulse_longrun_summary.csv

echo "case_name,CFL,Npulse,Ntotal,final_energy_ratio,post_pulse_growth_rate,result" > pulse_longrun_summary.csv

for item in \
  "test_pulse_2d_rz_tmz:2d_rz_tmz" \
  "test_pulse_2d_rz_tez:2d_rz_tez" \
  "test_pulse_3d_cartesian:3d_cartesian" \
  "test_pulse_3d_cyl_m0:3d_cyl_m0" \
  "test_pulse_3d_cyl_m1:3d_cyl_m1"
do
  exe="${item%%:*}"
  log_name="${item##*:}"
  fallback="${log_name},NA,${NPULSE},${NTOTAL},NA,NA,unstable"
  run_case_and_capture_summary \
    "${exe}" \
    "logs/${log_name}.log" \
    pulse_longrun_summary.csv \
    "${fallback}" \
    "${NTOTAL}" "${MONITOR_EVERY}" "${NPULSE}" "${PULSE_AMP}"
done

echo "Wrote logs under logs/ and summary file pulse_longrun_summary.csv"
