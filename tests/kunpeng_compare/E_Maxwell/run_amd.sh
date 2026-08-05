#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

for case_dir in E03_fdtd_3d_cartesian; do
  echo "=== ${case_dir} [amd] ==="
  bash "${SCRIPT_DIR}/${case_dir}/run_common.sh" amd "$@"
done

echo "All E_Maxwell AMD comparison cases finished."
