#!/bin/bash
set -e

# ===== user settings =====
FC=mpif90
RUNNER=mpirun
NPROC=8

# Relative to this script directory
HYPRE_INC=/home/wbs/install/hypre/src/hypre/include
HYPRE_LIB=/home/wbs/install/hypre/src/hypre/lib

EXE=test_d04_mpi_raz

SRC_MAIN=main_D04_test_multi_mpi_raz.f90

# ===== enter script directory =====
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

# ===== runtime library path =====
export LD_LIBRARY_PATH="${HYPRE_LIB}:${LD_LIBRARY_PATH}"

# ===== clean =====
rm -f "$EXE" *.o *.mod

# ===== compile =====
# The module file contains the solver and the two assembly subroutines
# via #include, so do not compile sub_D04_hypre_3Draz_nonuniform*.f90
# separately.
$FC -O2 -fdefault-real-8 -cpp -o "$EXE" \
    "$SRC_MAIN" \
    -I"${HYPRE_INC}" \
    -L"${HYPRE_LIB}" \
    -Wl,-rpath,"${HYPRE_LIB}" \
    -lHYPRE

# ===== run =====
$RUNNER -n "$NPROC" ./$EXE

python3 plot_phi_compare.py
