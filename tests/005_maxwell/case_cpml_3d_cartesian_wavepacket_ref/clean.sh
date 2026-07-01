#!/usr/bin/env bash
set -euo pipefail

rm -f ./*.o ./*.mod test_3d_cartesian_wavepacket_cpml.out
rm -f case_info.dat metrics.dat *_probe.dat
rm -f probe_compare.png probe_error_db.png field_slice_*.dat field_slices_*.png
for output_dir in output_*; do
  [[ -d "${output_dir}" ]] || continue
  rm -f "${output_dir}"/case_info.dat
  rm -f "${output_dir}"/metrics.dat
  rm -f "${output_dir}"/*_probe.dat
  rm -f "${output_dir}"/field_slice_*.dat
done
rm -rf __pycache__
