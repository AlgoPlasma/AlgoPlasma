#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
SOURCE_DIR="${SCRIPT_DIR}/source_f90"
J01_DIR="${REPO_ROOT}/J_Fluid/J01_continuity_freeflow"

FC="${FC:-gfortran}"
FCFLAGS=(
  -cpp
  -O0
  -g
  -fdefault-real-8
  -fcheck=all
  -fbacktrace
  -finit-real=snan
  -ffpe-trap=invalid,zero,overflow
  -Wall
  -Wextra
)

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

"${FC}" "${FCFLAGS[@]}" \
  -I"${J01_DIR}" -J"${BUILD_DIR}" \
  -c "${J01_DIR}/mod_J01_continuity_freeflow.f90" \
  -o "${BUILD_DIR}/mod_J01_continuity_freeflow.o"

"${FC}" "${FCFLAGS[@]}" \
  -I"${BUILD_DIR}" -J"${BUILD_DIR}" \
  -c "${SOURCE_DIR}/test_J01_continuity_freeflow.f90" \
  -o "${BUILD_DIR}/test_J01_continuity_freeflow.o"

"${FC}" "${FCFLAGS[@]}" \
  "${BUILD_DIR}/mod_J01_continuity_freeflow.o" \
  "${BUILD_DIR}/test_J01_continuity_freeflow.o" \
  -o "${BUILD_DIR}/test_J01_continuity_freeflow.out"

echo "Build complete: ${BUILD_DIR}/test_J01_continuity_freeflow.out"

