#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$HERE/make.sh"
status=0
for name in test_J01_continuity_freeflow test_J01_faceflux_2Drz_units test_J01_fm_units test_J01_corner_crossings test_J01_sampling_distribution; do
  "$HERE/build/${name}.out" | tee "$HERE/build/${name}.log" || status=$?
done
exit "$status"
