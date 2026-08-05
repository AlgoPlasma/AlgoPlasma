#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

FC="${FC:-gfortran}"
AMD_MARCH="${AMD_MARCH:-native}"
AMD_MTUNE="${AMD_MTUNE:-native}"
FCFLAGS="${FCFLAGS:--cpp -O3 -fdefault-real-8 -fopenmp -ffree-line-length-none -march=${AMD_MARCH} -mtune=${AMD_MTUNE}}"
case " ${FCFLAGS} " in
  *" -DALGOPLASMA_E03_USE_OMPDO "*) ;;
  *) FCFLAGS="${FCFLAGS} -DALGOPLASMA_E03_USE_OMPDO" ;;
esac
OMP_PROC_BIND="${OMP_PROC_BIND:-spread}"
OMP_PLACES="${OMP_PLACES:-cores}"
OMP_DYNAMIC="${OMP_DYNAMIC:-false}"
export FC FCFLAGS OMP_PROC_BIND OMP_PLACES OMP_DYNAMIC

echo "AMD ompdo compiler: ${FC}"
echo "AMD ompdo FCFLAGS: ${FCFLAGS}"
echo "OMP_PROC_BIND=${OMP_PROC_BIND}, OMP_PLACES=${OMP_PLACES}, OMP_DYNAMIC=${OMP_DYNAMIC}"

bash "${SCRIPT_DIR}/run_common.sh" amd_ompdo "$@"
