#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

cd "${SCRIPT_DIR}"
mkdir -p build

gfortran -cpp -Wall -Wextra -fcheck=bounds -fdefault-real-8 -I "${REPO_ROOT}" -o build/test_cross_section_loader source_f90/main.f90
