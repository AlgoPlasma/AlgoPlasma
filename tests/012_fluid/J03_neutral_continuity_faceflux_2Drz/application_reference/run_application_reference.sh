#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASE="${1:-}"
CASE_ROOT="${2:-$HERE/../application_inputs}"
export GFORTRAN_UNBUFFERED_ALL=y
if [[ "$CASE" != "B0" && "$CASE" != "ION" ]]; then
  echo "Usage: $0 B0|ION [CASE_DATA_ROOT]" >&2
  exit 2
fi
OUT="${APPLICATION_OUTPUT:-$HERE/build/application_reference/output_${CASE}}"
python3 "$HERE/../validate_application_inputs.py" "$CASE_ROOT"
if [[ -d "$OUT" ]] && [[ -n "$(ls -A "$OUT")" ]]; then
  echo "Output directory is not empty: $OUT; set APPLICATION_OUTPUT to a new path." >&2
  exit 2
fi
mkdir -p "$OUT/j02" "$OUT/j03"
bash "$HERE/make.sh"

echo "[Run] J02 full application case $CASE"
"$HERE/build/application_reference/run_J02_application_reference.out" \
  "$CASE" "$CASE_ROOT" "$OUT/j02" | tee "$OUT/j02/run.log"
echo "[Run] J03 continuity case $CASE"
"$HERE/build/application_reference/run_J03_application_reference.out" \
  "$CASE" "$CASE_ROOT" "$OUT/j02" "$OUT/j03" | tee "$OUT/j03/run.log"
echo "[Validate] J02 SN -> J03 application test"
python3 "$HERE/../plot_application.py" SN "$CASE_ROOT" "$OUT"
echo "[Done] report: $OUT/summary.txt"
echo "[Done] plots:  $OUT/*.png"
