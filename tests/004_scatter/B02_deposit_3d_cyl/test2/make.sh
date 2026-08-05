#!/usr/bin/env bash
set -euo pipefail

# Put this file in:
# ../algoplasma/tests/004_scatter/B02_deposit_3d_cyl/test2/
#
# Usage:
#   ./make.sh
#
# If your source directory is different, run:
#   SRC_DIR=/path/to/B02_deposit_3d_cyl ./make.sh
#
# Precision note:
#   The B02 source code uses default ``real`` without an explicit kind.
#   Therefore, ``-fdefault-real-8`` is required here so that default
#   real variables are compiled as 8-byte reals. This is important for
#   the continuity-equation residual test, which is very sensitive to
#   floating-point cancellation.

CASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${CASE_DIR}/../../../.." && pwd)"
TEST_DIR="${CASE_DIR}/test"
BUILD_DIR="${CASE_DIR}/build"

# Default B02 source directory.
SRC_DIR="${SRC_DIR:-${ROOT_DIR}/B_Scatter/B02_deposit_3d_cyl}"

FC="${FC:-gfortran}"
FFLAGS="${FFLAGS:--cpp -O2 -Wall -Wextra -fimplicit-none -fdefault-real-8}"

mkdir -p "${BUILD_DIR}"

echo "CASE_DIR  = ${CASE_DIR}"
echo "ROOT_DIR  = ${ROOT_DIR}"
echo "SRC_DIR   = ${SRC_DIR}"
echo "TEST_DIR  = ${TEST_DIR}"
echo "BUILD_DIR = ${BUILD_DIR}"
echo "FC        = ${FC}"
echo "FFLAGS    = ${FFLAGS}"
echo

if [[ ! -d "${SRC_DIR}" ]]; then
    echo "ERROR: SRC_DIR does not exist:"
    echo "       ${SRC_DIR}"
    echo
    echo "Please check the real B02 source path. You can locate it by:"
    echo "       cd ${ROOT_DIR}"
    echo "       find . -type f -name 'mod_B02_deposit_charge_3d_cyl.f90'"
    echo
    echo "Then compile with, for example:"
    echo "       SRC_DIR=/real/path/to/B02_deposit_3d_cyl ./make.sh"
    exit 1
fi

for f in \
    "${SRC_DIR}/mod_B02_deposit_charge_3d_cyl.f90" \
    "${SRC_DIR}/mod_B02_deposit_current_3d_cyl.f90"
do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: required source file not found:"
        echo "       $f"
        exit 1
    fi
done

find_first() {
    local pattern="$1"
    find "${TEST_DIR}" -maxdepth 1 -type f -name "${pattern}" | sort | head -n 1
}

CHARGE_TEST="${CHARGE_TEST:-$(find_first '*charge*.f90')}"
CURRENT_TEST="${CURRENT_TEST:-$(find_first '*current*.f90')}"

if [[ -z "${CHARGE_TEST}" || ! -f "${CHARGE_TEST}" ]]; then
    echo "ERROR: charge test .f90 not found in ${TEST_DIR}"
    echo "       You can set it manually:"
    echo "       CHARGE_TEST=${TEST_DIR}/test_charge_like_test2.f90 ./make.sh"
    exit 1
fi

if [[ -z "${CURRENT_TEST}" || ! -f "${CURRENT_TEST}" ]]; then
    echo "ERROR: current test .f90 not found in ${TEST_DIR}"
    echo "       You can set it manually:"
    echo "       CURRENT_TEST=${TEST_DIR}/test_current_like_test2_rewritten.f90 ./make.sh"
    exit 1
fi

echo "CHARGE_TEST  = ${CHARGE_TEST}"
echo "CURRENT_TEST = ${CURRENT_TEST}"
echo

# The sub_*.f90 files should be included by the corresponding mod_*.f90 files.
# Therefore only module files are listed here.
B02_SRC_FILES=(
    "${SRC_DIR}/mod_B02_deposit_charge_3d_cyl.f90"
    "${SRC_DIR}/mod_B02_deposit_current_3d_cyl.f90"
)

# Compile the axis-average module only if it exists and is used by tests.
# The current manual-average test scripts do not require it, but keeping this
# optional block makes the script compatible with both versions.
if [[ -f "${SRC_DIR}/mod_B02_average_axis_3d_cyl.f90" ]]; then
    B02_SRC_FILES+=("${SRC_DIR}/mod_B02_average_axis_3d_cyl.f90")
fi

echo "Compiling charge deposition test..."
"${FC}" ${FFLAGS} -J "${BUILD_DIR}" -I "${SRC_DIR}" -I "${BUILD_DIR}" \
    "${B02_SRC_FILES[@]}" "${CHARGE_TEST}" \
    -o "${BUILD_DIR}/test_charge"

echo
echo "Compiling current deposition test..."
"${FC}" ${FFLAGS} -J "${BUILD_DIR}" -I "${SRC_DIR}" -I "${BUILD_DIR}" \
    "${B02_SRC_FILES[@]}" "${CURRENT_TEST}" \
    -o "${BUILD_DIR}/test_current"

echo
echo "Build completed:"
echo "  ${BUILD_DIR}/test_charge"
echo "  ${BUILD_DIR}/test_current"
