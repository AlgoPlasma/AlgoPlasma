#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

select_bisheng_fc() {
  if [[ -n "${FC:-}" ]]; then
    return
  fi

  local candidate
  for candidate in flang bisheng-flang biflang flang-new; do
    if command -v "${candidate}" >/dev/null 2>&1; then
      FC="${candidate}"
      export FC
      return
    fi
  done

  echo "ERROR: Bisheng Fortran compiler was not found. Load Bisheng or set FC=/path/to/flang." >&2
  exit 1
}

# Load Bisheng toolchain config from cluster
if [[ -z "${FC:-}" && -f /home/hpcuser/build_config.sh ]]; then
  export TOOLCHAIN="${TOOLCHAIN:-bisheng}"
  source /home/hpcuser/build_config.sh
fi

select_bisheng_fc

KUNPENG_MCPU="${KUNPENG_MCPU:-native}"
FCFLAGS="${FCFLAGS:--cpp -O3 -fdefault-real-8 -fopenmp -ffree-line-length-none -mcpu=${KUNPENG_MCPU}}"
OMP_PROC_BIND="${OMP_PROC_BIND:-spread}"
OMP_PLACES="${OMP_PLACES:-cores}"
OMP_DYNAMIC="${OMP_DYNAMIC:-false}"
export FC FCFLAGS OMP_PROC_BIND OMP_PLACES OMP_DYNAMIC

echo "Kunpeng optimized compiler: ${FC}"
echo "Kunpeng optimized FCFLAGS: ${FCFLAGS}"
echo "OMP_PROC_BIND=${OMP_PROC_BIND}, OMP_PLACES=${OMP_PLACES}, OMP_DYNAMIC=${OMP_DYNAMIC}"

for case_dir in E03_fdtd_3d_cartesian; do
  echo "=== ${case_dir} [kunpeng_optimized] ==="
  bash "${SCRIPT_DIR}/${case_dir}/run_common.sh" kunpeng_optimized "$@"
done

echo "All E_Maxwell Kunpeng optimized comparison cases finished."
