#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
BUILD="${SCRIPT_DIR}/build"
FC="${FC:-gfortran}"
FLAGS=(-cpp -O0 -g -std=f2008 -fdefault-real-8 -fcheck=all -fbacktrace \
  -finit-real=snan -ffpe-trap=invalid,zero,overflow -Wall -Wextra)
rm -rf "${BUILD}"
mkdir -p "${BUILD}"
for unit in J01_neutral_free_molecular_2Drz J02_neutral_sn_transport_2Drz J03_neutral_continuity_faceflux_2Drz; do
  directory="${ROOT}/J_Fluid/${unit}"
  if [[ "${unit}" == J01_* ]]; then directory="${ROOT}/J_Fluid/J01_free_molecular"; fi
  source="${directory}/mod_${unit}.f90"
  "${FC}" "${FLAGS[@]}" -I"${directory}" -J"${BUILD}" -c "${source}" \
    -o "${BUILD}/mod_${unit}.o"
done
"${FC}" "${FLAGS[@]}" -J"${BUILD}" -c "${SCRIPT_DIR}/application_case.f90" -o "${BUILD}/mod_application_case.o"
for source in "${SCRIPT_DIR}"/source_f90/test_*.f90; do
  name="$(basename "${source}" .f90)"
  "${FC}" "${FLAGS[@]}" -I"${BUILD}" -I"${SCRIPT_DIR}" -J"${BUILD}" -c "${source}" \
    -o "${BUILD}/${name}.o"
  "${FC}" "${FLAGS[@]}" "${BUILD}"/mod_*.o "${BUILD}/${name}.o" \
    -o "${BUILD}/${name}.out"
  echo "Build complete: ${BUILD}/${name}.out"
done
