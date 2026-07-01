#!/usr/bin/env bash
set -euo pipefail

rm -f ./*.o ./*.mod ./*.out
rm -f metrics.dat case_info.dat *_probe.dat
rm -f er_snapshot_*.dat ez_snapshot_*.dat ha_snapshot_*.dat
rm -f er_final_*.dat ez_final_*.dat ha_final_*.dat
rm -f probe_compare.png probe_error_db.png er_snapshots_*.png ez_snapshots_*.png ha_snapshots_*.png

rm -f output_lambda12mm_npml14/*.dat
rm -f output_lambda12mm_npml14/probe_compare.png
rm -f output_lambda12mm_npml14/er_snapshots_*.png
rm -f output_lambda12mm_npml14/ha_snapshots_*.png
rm -f output_lambda12mm_npml14/ez_snapshots_z_plus.png
rm -f output_lambda12mm_npml14/ez_snapshots_z_minus.png
