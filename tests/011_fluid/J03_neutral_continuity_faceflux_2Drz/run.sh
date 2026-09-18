#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "${SCRIPT_DIR}/make.sh"
status=0
for executable in "${SCRIPT_DIR}"/build/test_*.out; do
  name="$(basename "${executable}" .out)"
  "${executable}" | tee "${SCRIPT_DIR}/build/${name}.log" || status=$?
done
exit "${status}"
