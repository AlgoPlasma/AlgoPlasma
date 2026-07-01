#!/usr/bin/env bash
set -euo pipefail

rm -f ./*.o ./*.mod ./*.out
rm -f metrics.dat case_info.dat *_probe.dat
rm -f field_slice_*.dat probe_compare.png probe_error_db.png field_slices_*.png
rm -rf __pycache__

rm -f output_lambda18mm_npml12_gif/*.dat
