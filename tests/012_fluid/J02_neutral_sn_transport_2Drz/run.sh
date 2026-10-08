#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"
bash clean.sh
bash make.sh
status=0
for executable in build/test_*.out; do
  name="$(basename "${executable}" .out)"
  "${executable}" | tee "build/${name}.log" || status=$?
done
exit "${status}"
