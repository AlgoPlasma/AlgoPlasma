#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

platform="${ALGOPLASMA_PLATFORM:-$(uname -m)}"

for case_dir in E03_fdtd_3d_cartesian; do
  echo "=== ${case_dir} ==="
  bash "${SCRIPT_DIR}/${case_dir}/run_common.sh" "${platform}" "$@"
done

echo "All E_Maxwell comparison cases finished."
