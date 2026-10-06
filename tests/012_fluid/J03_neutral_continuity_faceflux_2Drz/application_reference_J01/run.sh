#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASE_ROOT="${1:-$HERE/../application_inputs}"
N_HISTORIES="${2:-${J01_FM_HISTORIES:-2400000}}"
OUT="${APPLICATION_OUTPUT:-$HERE/build/output_B0}"
python3 "$HERE/../validate_application_inputs.py" "$CASE_ROOT"
if [[ -d "$OUT" ]] && [[ -n "$(ls -A "$OUT")" ]]; then
  echo "Output directory is not empty: $OUT; set APPLICATION_OUTPUT to a new path." >&2
  exit 2
fi
export GFORTRAN_UNBUFFERED_ALL=y
mkdir -p "$OUT/j01" "$OUT/j03"
bash "$HERE/make.sh"
echo "[Run] J01 B0 independent free-molecular calculation ($N_HISTORIES histories)"
"$HERE/build/run_J01_application_reference.out" "$CASE_ROOT" "$OUT/j01" "$N_HISTORIES" | tee "$OUT/j01/run.log"
echo "[Run] J03 from J01 face flux"
"$HERE/build/run_J03_from_J01_reference.out" "$CASE_ROOT" "$OUT/j01" "$OUT/j03" | tee "$OUT/j03/run.log"
echo "[Validate] J01 FM -> J03 application test"
python3 "$HERE/../plot_application.py" FM "$CASE_ROOT" "$OUT"
echo "[Done] report: $OUT/summary.txt"
echo "[Done] plots:  $OUT/*.png"
