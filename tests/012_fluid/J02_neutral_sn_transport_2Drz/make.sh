#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
SOURCE_DIR="${SCRIPT_DIR}/source_f90"
J02_DIR="${REPO_ROOT}/J_Fluid/J02_neutral_sn_transport_2Drz"
FC="${FC:-gfortran}"
FCFLAGS=(-cpp -O0 -g -std=f2008 -fdefault-real-8 -fcheck=all -fbacktrace \
  -finit-real=snan \
  -ffpe-trap=invalid,zero,overflow -Wall -Wextra)

case "${OPENMP:-0}" in
  1) FCFLAGS+=(-fopenmp) ;;
  0) ;;
  *) echo "OPENMP must be 0 or 1" >&2; exit 2 ;;
esac

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

module_object="${BUILD_DIR}/mod_J02_neutral_sn_transport_2Drz.o"
"${FC}" "${FCFLAGS[@]}" -I"${J02_DIR}" -J"${BUILD_DIR}" \
  -c "${J02_DIR}/mod_J02_neutral_sn_transport_2Drz.f90" \
  -o "${module_object}"

for source in "${SOURCE_DIR}"/test_*.f90; do
  name="$(basename "${source}" .f90)"
  if [[ "${name}" == test_J02_mpi ]]; then continue; fi
  "${FC}" "${FCFLAGS[@]}" -I"${BUILD_DIR}" -J"${BUILD_DIR}" \
    -c "${source}" -o "${BUILD_DIR}/${name}.o"
  "${FC}" "${FCFLAGS[@]}" "${module_object}" "${BUILD_DIR}/${name}.o" \
    -o "${BUILD_DIR}/${name}.out"
  echo "Build complete: ${BUILD_DIR}/${name}.out"
done
