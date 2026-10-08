#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
mkdir -p "${SCRIPT_DIR}/build"
cd "${SCRIPT_DIR}/build"
"${FC:-gfortran}" -cpp -O2 -fdefault-real-8 -Wall -Wextra -fcheck=all -fbacktrace \
    "${REPO_ROOT}/C_Gather/C03_gather_3Draz_nonuniform/mod_C03_gather_3Draz_nonuniform.f90" \
    "${SCRIPT_DIR}/source_f90/main.f90" -o main
printf 'Build complete: %s/build/main\n' "${SCRIPT_DIR}"
