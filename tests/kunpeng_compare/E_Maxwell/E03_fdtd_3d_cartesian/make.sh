#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

FC="${FC:-gfortran}"
FCFLAGS="${FCFLAGS:--cpp -O3 -fdefault-real-8 -fopenmp -ffree-line-length-none}"

mkdir -p build output

"${FC}" ${FCFLAGS} -J build \
  source_f90/main.f90 \
  -o build/e03_fdtd_3d_cartesian_bench.out

{
  echo "FC=${FC}"
  echo "FCFLAGS=${FCFLAGS}"
  "${FC}" --version | head -n 1
} > output/build_info.txt

echo "Build complete: ${SCRIPT_DIR}/build/e03_fdtd_3d_cartesian_bench.out"

