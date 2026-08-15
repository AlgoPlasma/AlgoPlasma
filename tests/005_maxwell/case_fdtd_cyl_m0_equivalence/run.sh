#!/usr/bin/env bash
set -euo pipefail

NSTEPS_EQUIV="${1:-600}"

./make.sh

mkdir -p logs
rm -f logs/*.log m0_equivalence_summary.csv

echo "summary_line" > m0_equivalence_summary.csv

log_path="logs/m0_equivalence.log"
./test_geom_m0_equivalence.out "${NSTEPS_EQUIV}" | tee "${log_path}"

if grep -q '^SUMMARY_CSV,' "${log_path}"; then
  sed -n 's/^SUMMARY_CSV,//p' "${log_path}" >> m0_equivalence_summary.csv
fi

echo "Wrote logs under logs/ and summary file m0_equivalence_summary.csv"
