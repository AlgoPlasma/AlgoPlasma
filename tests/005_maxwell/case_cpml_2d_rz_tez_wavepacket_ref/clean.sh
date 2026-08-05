#!/usr/bin/env bash
set -euo pipefail

rm -f ./*.o ./*.mod test_rz_tez_wavepacket_cpml.out
rm -f case_info.dat metrics.dat *_probe.dat hz_final_*.dat ephi_final_*.dat
rm -f hz_snapshot_*.dat ephi_snapshot_*.dat
rm -f probe_compare.png probe_error_db.png hz_snapshots_*.png ephi_snapshots_*.png
rm -f hz_animation_*.gif ephi_animation_*.gif
rm -f wavelength_sweep_summary.csv equal_lambda_npml_sweep_summary.csv
rm -rf __pycache__
rm output_lambda12mm_npml12_weak_ephi_gif/*.dat
