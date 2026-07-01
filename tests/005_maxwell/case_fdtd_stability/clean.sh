#!/usr/bin/env bash
set -euo pipefail

rm -f *.o *.mod *.out *.log
rm -f stability_summary.csv
rm -rf logs

echo "Clean complete."
