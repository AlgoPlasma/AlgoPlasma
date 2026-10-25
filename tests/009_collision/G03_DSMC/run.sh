#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
MODULE_DIR="$(cd -- "${TEST_DIR}/../../../G_Collision/G03_DSMC" && pwd)"
COMPILER="${CXX:-g++}"
GROUP="${1:-all}"
case "${GROUP}" in
    all|build|plots|models|scattering|random|geometry|conservation|schedules|replay|errors|relaxation) ;;
    *) echo "usage: bash run.sh [all|build|plots|models|scattering|random|geometry|conservation|schedules|replay|errors|relaxation]" >&2; exit 2 ;;
esac

RESULTS_DIR="${TEST_DIR}/results"
PYTHON="${PYTHON:-python3}"
if [[ "${GROUP}" != build ]]; then
    mkdir -p -- "${RESULTS_DIR}"
    exec > >(tee "${RESULTS_DIR}/run.log") 2>&1
    echo "Run: ${GROUP}, $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Results: ${RESULTS_DIR}"
fi
if [[ "${GROUP}" == all || "${GROUP}" == relaxation || "${GROUP}" == plots ]]; then
    "${PYTHON}" -c 'import matplotlib' || {
        echo "ERROR: plotting requires Python 3 and Matplotlib; select the interpreter with PYTHON" >&2
        exit 2
    }
fi
if [[ "${GROUP}" == plots ]]; then
    "${PYTHON}" "${TEST_DIR}/plot_results.py" "${RESULTS_DIR}"
    exit 0
fi

AUTO_BUILD=0
if [[ -n "${G03_DSMC_BUILD_DIR:-}" ]]; then
    BUILD_DIR="$(realpath -m -- "${G03_DSMC_BUILD_DIR}")"
    REPO_DIR="$(cd -- "${TEST_DIR}/../../.." && pwd)"
    if [[ "${BUILD_DIR}" == / || "${BUILD_DIR}" == "${REPO_DIR}" ||
          "${BUILD_DIR}" == "${MODULE_DIR}" || "${BUILD_DIR}" == "${TEST_DIR}" ]]; then
        echo "ERROR: build directory must differ from the source directories" >&2
        exit 2
    fi
    mkdir -p -- "${BUILD_DIR}"
else
    BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/g03-dsmc-tests.XXXXXX")"
    AUTO_BUILD=1
fi
cleanup() {
    # 仅清理由本脚本通过 mktemp 创建的目录；显式指定的构建目录始终保留。
    if [[ "${AUTO_BUILD}" == 1 && "${BUILD_DIR}" == */g03-dsmc-tests.* ]]; then
        rm -rf -- "${BUILD_DIR}"
    fi
}
trap cleanup EXIT
if [[ "${GROUP}" == build && "${AUTO_BUILD}" == 1 ]]; then
    echo "ERROR: set G03_DSMC_BUILD_DIR when using build" >&2
    exit 2
fi

FLAGS=(-std=c++20 -Wall -Wextra -Wpedantic -Werror -I"${MODULE_DIR}")
case "${G03_DSMC_SANITIZERS:-0}" in
    0) FLAGS+=(-O2) ;;
    1) FLAGS+=(-O1 -g -fno-omit-frame-pointer -fsanitize=address,undefined) ;;
    *) echo "ERROR: G03_DSMC_SANITIZERS must be 0 or 1" >&2; exit 2 ;;
esac
SOURCES=(calibration collision cylindrical model particles rate scatter stepper)
OBJECTS=()
for name in "${SOURCES[@]}"; do
    object="${BUILD_DIR}/${name}.o"
    "${COMPILER}" "${FLAGS[@]}" -c "${MODULE_DIR}/fun_G03_dsmc_${name}.cpp" -o "${object}"
    OBJECTS+=("${object}")
done
"${COMPILER}" "${FLAGS[@]}" "${TEST_DIR}"/cpp/*.cpp "${OBJECTS[@]}" -o "${BUILD_DIR}/dsmc_tests"
"${COMPILER}" "${FLAGS[@]}" "${TEST_DIR}/examples/relaxation.cpp" "${OBJECTS[@]}" -o "${BUILD_DIR}/relaxation"
echo "Build: ${BUILD_DIR}"
echo "Compiler: ${COMPILER} ${FLAGS[*]}"
if [[ "${GROUP}" == build ]]; then exit 0; fi

for name in models scattering random geometry conservation schedules replay errors; do
    if [[ "${GROUP}" == all || "${GROUP}" == "${name}" ]]; then
        "${BUILD_DIR}/dsmc_tests" "${name}"
    fi
done
if [[ "${GROUP}" == all || "${GROUP}" == relaxation ]]; then
    for model in HS VHS VSS; do
        for schedule in ntc clock; do
            "${BUILD_DIR}/relaxation" "${model}" "${schedule}" --check \
                > "${RESULTS_DIR}/relaxation-${model}-${schedule}.csv"
        done
    done
    "${PYTHON}" "${TEST_DIR}/plot_results.py" "${RESULTS_DIR}"
fi
echo "PASS: G03 DSMC ${GROUP}"
