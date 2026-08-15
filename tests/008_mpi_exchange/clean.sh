#!/usr/bin/env bash
set -euo pipefail

CASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${CASE_DIR}/build"
FIG_DIR="${CASE_DIR}/fig"

mkdir -p "${BUILD_DIR}" "${FIG_DIR}"

rm -f "${BUILD_DIR}"/*.dat
rm -f "${BUILD_DIR}"/*.log
rm -f "${BUILD_DIR}"/*.o
rm -f "${BUILD_DIR}"/*.mod
rm -f "${BUILD_DIR}"/*.smod
rm -f "${BUILD_DIR}"/*.exe
rm -f "${BUILD_DIR}"/*.out
rm -f "${FIG_DIR}"/*.png
rm -f "${FIG_DIR}"/*.pdf

echo "Cleaned H_MPI_Exchange test data, figures, and compile cache."
