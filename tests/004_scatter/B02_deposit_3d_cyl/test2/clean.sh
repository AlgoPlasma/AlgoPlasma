#!/usr/bin/env bash
set -euo pipefail

# This script should be placed in:
# algoplasma/tests/004_scatter/B02_deposit_3d_cyl/test2/

CASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${CASE_DIR}"

echo "Cleaning generated data, figures, and build products..."

rm -f ./*.dat ./*.png
rm -f ./test/*.dat ./test/*.png
rm -f ./plot/*.dat ./plot/*.png
rm -rf ./build

echo "Clean completed."
