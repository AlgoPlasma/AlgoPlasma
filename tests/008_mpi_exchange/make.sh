#!/usr/bin/env bash
set -euo pipefail

CASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${CASE_DIR}/../.." && pwd)"
BUILD_DIR="${CASE_DIR}/build"

FC="${FC:-mpif90}"
FFLAGS="${FFLAGS:--cpp -O2 -fdefault-real-8 -ffree-line-length-none}"
LDFLAGS="${LDFLAGS:-}"

H01="${ROOT_DIR}/H_MPI_Exchange/H01_mpi_exchange_field"
H02="${ROOT_DIR}/H_MPI_Exchange/H02_mpi_exchange_par"
H03="${ROOT_DIR}/H_MPI_Exchange/H03_mpi_exchange_den"

mkdir -p "${BUILD_DIR}"

echo "Compiling H_MPI_Exchange regression test with ${FC}"

"${FC}" ${FFLAGS} -J "${BUILD_DIR}" -I "${H01}" -I "${H02}" -I "${H03}" \
  -c "${H01}/mod_H01_mpi_exchange_field.f90" \
  -o "${BUILD_DIR}/mod_H01_mpi_exchange_field.o"

"${FC}" ${FFLAGS} -J "${BUILD_DIR}" -I "${H01}" -I "${H02}" -I "${H03}" \
  -c "${H02}/mod_H02_mpi_exchange_par.f90" \
  -o "${BUILD_DIR}/mod_H02_mpi_exchange_par.o"

"${FC}" ${FFLAGS} -J "${BUILD_DIR}" -I "${H01}" -I "${H02}" -I "${H03}" \
  -c "${H03}/mod_H03_mpi_exchange_den.f90" \
  -o "${BUILD_DIR}/mod_H03_mpi_exchange_den.o"

"${FC}" ${FFLAGS} -J "${BUILD_DIR}" -I "${H01}" -I "${H02}" -I "${H03}" \
  -c "${CASE_DIR}/test_H_MPI_Exchange.f90" \
  -o "${BUILD_DIR}/test_H_MPI_Exchange.o"

"${FC}" ${FFLAGS} ${LDFLAGS} -o "${BUILD_DIR}/test_H_MPI_Exchange.exe" \
  "${BUILD_DIR}/mod_H01_mpi_exchange_field.o" \
  "${BUILD_DIR}/mod_H02_mpi_exchange_par.o" \
  "${BUILD_DIR}/mod_H03_mpi_exchange_den.o" \
  "${BUILD_DIR}/test_H_MPI_Exchange.o"

echo "Built ${BUILD_DIR}/test_H_MPI_Exchange.exe"
