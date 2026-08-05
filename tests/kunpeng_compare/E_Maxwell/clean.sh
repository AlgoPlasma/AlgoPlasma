#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

for case_dir in E03_fdtd_3d_cartesian; do
  bash "${SCRIPT_DIR}/${case_dir}/clean.sh"
done

echo "Cleaned E_Maxwell comparison cases."
