#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

mkdir -p build
cd build

gfortran -cpp -O2 -fdefault-real-8 -fopenmp ../source_f90/main.f90 -o main

echo "Build complete: ${SCRIPT_DIR}/build/main"
