#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
J02_DIR="${REPO_ROOT}/J_Fluid/J02_neutral_sn_transport_2Drz"
BUILD_DIR="${1:-${SCRIPT_DIR}/../build/cex_coefficients}"
FC="${FC:-gfortran}"
mkdir -p "${BUILD_DIR}"
"${FC}" -cpp -O0 -g -std=f2008 -fdefault-real-8 -fcheck=all \
  -ffpe-trap=invalid,zero,overflow -Wall -Wextra \
  -I"${J02_DIR}" -I"${BUILD_DIR}" -J"${BUILD_DIR}" \
  "${J02_DIR}/mod_J02_neutral_sn_transport_2Drz.f90" \
  "${SCRIPT_DIR}/../source_f90/test_J02_cex_coefficients.f90" \
  -o "${BUILD_DIR}/test_cex.out"
"${BUILD_DIR}/test_cex.out"
