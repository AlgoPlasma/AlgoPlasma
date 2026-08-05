#!/usr/bin/env bash
set -euo pipefail

# This script should be placed in:
# algoplasma/tests/004_scatter/B02_deposit_3d_cyl/test1/

CASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${CASE_DIR}/build"
PLOT_DIR="${CASE_DIR}/plot"

NP="${1:-}"

find_first() {
    local pattern="$1"
    find "${PLOT_DIR}" -maxdepth 1 -type f -name "${pattern}" | sort | head -n 1
}

CHARGE_PLOT="${CHARGE_PLOT:-}"
CURRENT_PLOT="${CURRENT_PLOT:-}"

if [[ -z "${CHARGE_PLOT}" ]]; then
    CHARGE_PLOT="$(find_first '*charge*.py')"
fi

if [[ -z "${CURRENT_PLOT}" ]]; then
    CURRENT_PLOT="$(find_first '*current*.py')"
fi

if [[ ! -x "${BUILD_DIR}/test_charge" || ! -x "${BUILD_DIR}/test_current" ]]; then
    echo "Executables not found. Run ./make.sh first."
    exit 1
fi

cd "${CASE_DIR}"

echo "Running charge deposition test..."
if [[ -n "${NP}" ]]; then
    "${BUILD_DIR}/test_charge" "${NP}"
else
    "${BUILD_DIR}/test_charge"
fi

echo
echo "Running current deposition test..."
if [[ -n "${NP}" ]]; then
    "${BUILD_DIR}/test_current" "${NP}"
else
    "${BUILD_DIR}/test_current"
fi

echo
if [[ -n "${CHARGE_PLOT}" && -f "${CHARGE_PLOT}" ]]; then
    echo "Plotting charge deposition results with ${CHARGE_PLOT}..."
    python3 "${CHARGE_PLOT}"
else
    echo "WARNING: charge plot script not found in ${PLOT_DIR}"
    echo "         You can set it manually:"
    echo "         CHARGE_PLOT=${PLOT_DIR}/your_charge_plot.py ./run.sh"
fi

echo
if [[ -n "${CURRENT_PLOT}" && -f "${CURRENT_PLOT}" ]]; then
    echo "Plotting current deposition results with ${CURRENT_PLOT}..."
    python3 "${CURRENT_PLOT}"
else
    echo "WARNING: current plot script not found in ${PLOT_DIR}"
    echo "         You can set it manually:"
    echo "         CURRENT_PLOT=${PLOT_DIR}/your_current_plot.py ./run.sh"
fi

echo
echo "Run completed."
