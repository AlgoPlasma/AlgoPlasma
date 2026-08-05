#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

if [[ -z "${FC:-}" && -f /home/hpcuser/build_config.sh ]]; then
  export TOOLCHAIN="${TOOLCHAIN:-gcc}"
  source /home/hpcuser/build_config.sh
fi

FC="${FC:-gfortran}"
KUNPENG_MCPU="${KUNPENG_MCPU:-native}"
FCFLAGS="${FCFLAGS:--cpp -O3 -fdefault-real-8 -fopenmp -ffree-line-length-none -mcpu=${KUNPENG_MCPU}}"
OMP_PROC_BIND="${OMP_PROC_BIND:-spread}"
OMP_PLACES="${OMP_PLACES:-cores}"
OMP_DYNAMIC="${OMP_DYNAMIC:-false}"
export FC FCFLAGS OMP_PROC_BIND OMP_PLACES OMP_DYNAMIC

echo "Kunpeng compiler: ${FC}"
echo "Kunpeng FCFLAGS: ${FCFLAGS}"
echo "OMP_PROC_BIND=${OMP_PROC_BIND}, OMP_PLACES=${OMP_PLACES}, OMP_DYNAMIC=${OMP_DYNAMIC}"

for case_dir in E03_fdtd_3d_cartesian; do
  echo "=== ${case_dir} [kunpeng] ==="
  bash "${SCRIPT_DIR}/${case_dir}/run_common.sh" kunpeng "$@"
done

echo "All E_Maxwell Kunpeng comparison cases finished."
