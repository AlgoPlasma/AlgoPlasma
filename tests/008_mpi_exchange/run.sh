#!/usr/bin/env bash
set -euo pipefail

CASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${CASE_DIR}/build"
FIG_DIR="${CASE_DIR}/fig"
EXE="${BUILD_DIR}/test_H_MPI_Exchange.exe"

MPIEXEC="${MPIEXEC:-${RUNNER:-mpiexec}}"
MPIEXEC_ARGS="${MPIEXEC_ARGS:-}"
MPI_NP_FLAG="${MPI_NP_FLAG:--n}"
NP="${NP:-4}"
BUILD="${BUILD:-1}"
PLOT="${PLOT:-1}"

mkdir -p "${BUILD_DIR}" "${FIG_DIR}"

if [[ "${BUILD}" != "0" || ! -x "${EXE}" ]]; then
  bash "${CASE_DIR}/make.sh"
fi

echo "Running H_MPI_Exchange regression test with ${MPIEXEC} ${MPI_NP_FLAG} ${NP}"
(
  cd "${CASE_DIR}"
  ${MPIEXEC} ${MPIEXEC_ARGS} "${MPI_NP_FLAG}" "${NP}" "${EXE}"
)

if [[ "${PLOT}" != "0" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 "${CASE_DIR}/plot_mpi_exchange.py"
  elif command -v python >/dev/null 2>&1; then
    python "${CASE_DIR}/plot_mpi_exchange.py"
  else
    echo "WARNING: python/python3 not found; skip plotting."
  fi
fi
