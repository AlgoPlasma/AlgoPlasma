#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"
BUILD="${HERE}/build"
SRC="${ROOT}/J_Fluid/J02_neutral_sn_transport_2Drz"
OPENMP_FLAGS=()
case "${OPENMP:-1}" in
    1) OPENMP_FLAGS=(-fopenmp) ;;
    0) ;;
    *) echo "OPENMP must be 0 or 1" >&2; exit 2 ;;
esac
mkdir -p "${BUILD}"
"${FC:-gfortran}" "${OPENMP_FLAGS[@]}" -cpp -O2 -fdefault-real-8 -fcheck=all -ffree-line-length-none \
    -J"${BUILD}" -I"${SRC}" \
    "${SRC}/mod_J02_neutral_sn_transport_2Drz.f90" "${HERE}/sn_channel.f90" \
    -o "${BUILD}/sn_channel.out"
"${BUILD}/sn_channel.out"
