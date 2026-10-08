#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Build G02_MCC_network in a fresh temporary directory and run every test.
#
# Environment overrides:
#   G02_MCC_BUILD_DIR   build directory (default: a new mktemp directory).
#                       When set it must be empty; it must not be /, the source
#                       tree or any existing non-empty directory. It is never
#                       removed with an unguarded rm -rf.
#   G02_MCC_SANITIZERS  ON/OFF, default ON (ASan + UBSan)
#   G02_MCC_KEEP_BUILD  1 keeps an auto-created mktemp build directory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MODULE_DIR="${REPO_ROOT}/G_Collision/G02_MCC_network"

AUTO_CLEAN=0
if [[ -n "${G02_MCC_BUILD_DIR:-}" ]]; then
    BUILD_DIR="${G02_MCC_BUILD_DIR}"
    if [[ "${BUILD_DIR}" == "/" ]]; then
        echo "ERROR: G02_MCC_BUILD_DIR must not be /" >&2
        exit 2
    fi
    if command -v realpath >/dev/null 2>&1; then
        RESOLVED="$(realpath -m -- "${BUILD_DIR}")"
    else
        RESOLVED="$(cd "$(dirname "${BUILD_DIR}")" && pwd)/$(basename "${BUILD_DIR}")"
    fi
    case "${RESOLVED}" in
        "${REPO_ROOT}"|"${REPO_ROOT}"/*|"${SCRIPT_DIR}"|"${SCRIPT_DIR}"/*|"${MODULE_DIR}"|"${MODULE_DIR}"/*)
            echo "ERROR: refusing to use a source directory as G02_MCC_BUILD_DIR: ${RESOLVED}" >&2
            exit 2
            ;;
    esac
    if [[ -e "${RESOLVED}" ]]; then
        if [[ ! -d "${RESOLVED}" ]]; then
            echo "ERROR: G02_MCC_BUILD_DIR exists and is not a directory: ${RESOLVED}" >&2
            exit 2
        fi
        if [[ -n "$(ls -A -- "${RESOLVED}" 2>/dev/null || true)" ]]; then
            echo "ERROR: G02_MCC_BUILD_DIR must be empty: ${RESOLVED}" >&2
            exit 2
        fi
    else
        mkdir -p -- "${RESOLVED}"
    fi
    BUILD_DIR="${RESOLVED}"
else
    BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/g02_mcc_build.XXXXXX")"
    AUTO_CLEAN=1
fi

SANITIZERS="${G02_MCC_SANITIZERS:-ON}"

echo "== configure =="
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DG02_MCC_ENABLE_SANITIZERS="${SANITIZERS}"

echo "== build =="
cmake --build "${BUILD_DIR}" -j 4

echo "== test =="
ctest --test-dir "${BUILD_DIR}" --output-on-failure

if [[ "${AUTO_CLEAN}" == "1" && "${G02_MCC_KEEP_BUILD:-0}" != "1" ]]; then
    rm -rf -- "${BUILD_DIR}"
fi

echo "PASS: G02_MCC_network build and ctest suite"
