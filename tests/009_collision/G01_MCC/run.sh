#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

bash make.sh
./build/test_cross_section_loader

set +e
overflow_output="$(./build/test_cross_section_loader_too_many 2>&1)"
overflow_status=$?
set -e

printf '%s\n' "${overflow_output}"

if [[ ${overflow_status} -eq 0 ]]; then
  echo "FAIL: oversized cross-section table returned a zero exit status."
  exit 1
fi

if grep -q "AddressSanitizer" <<< "${overflow_output}"; then
  echo "FAIL: oversized cross-section table caused an out-of-bounds access."
  exit 1
fi

if ! grep -q "ERROR: i > Nmax in sub_G01_load_cross_section." <<< "${overflow_output}"; then
  echo "FAIL: expected oversized-table diagnostic was not printed."
  exit 1
fi

echo "PASS: oversized cross-section table rejected without an out-of-bounds access."
