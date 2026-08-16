#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

cd "${SCRIPT_DIR}"
mkdir -p build

COMMON_FLAGS=(
  -cpp
  -Wall
  -Wextra
  -fcheck=bounds
  -fdefault-real-8
  -fsanitize=address
  -fno-omit-frame-pointer
)

gfortran "${COMMON_FLAGS[@]}" -I "${REPO_ROOT}" \
  -o build/test_cross_section_loader source_f90/main.f90

gfortran "${COMMON_FLAGS[@]}" -I "${REPO_ROOT}" \
  -o build/test_cross_section_loader_too_many source_f90/test_too_many_rows.f90
