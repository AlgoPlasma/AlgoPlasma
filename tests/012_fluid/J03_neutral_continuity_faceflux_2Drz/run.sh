#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "${SCRIPT_DIR}/make.sh"
status=0
for name in test_J03_continuity_units test_J03_equilibrium test_J03_transient test_application_case \
  test_J01_J03_channel test_J02_J03_analytic; do
  executable="${SCRIPT_DIR}/build/${name}.out"
  "${executable}" | tee "${SCRIPT_DIR}/build/${name}.log" || status=$?
done
exit "${status}"
