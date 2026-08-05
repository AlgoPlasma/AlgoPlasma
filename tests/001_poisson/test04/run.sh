#!/bin/bash
set -e

# ===== user settings =====
FC=mpif90
RUNNER=mpirun
NPROC=8

# Relative to this script directory
HYPRE_INC=/home/wbs/install/hypre/src/hypre/include
HYPRE_LIB=/home/wbs/install/hypre/src/hypre/lib

EXE=test_d03_bc
SRC_MAIN=main_D03_test_bc_uniform_mpi.f90
PLOT_SCRIPT=plot_D03_bc.py

# ===== enter script directory =====
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

# ===== runtime library path =====
export LD_LIBRARY_PATH="${HYPRE_LIB}:${LD_LIBRARY_PATH}"

# ===== clean =====
rm -f "$EXE" *.o *.mod
rm -f case1_phi_compare.dat case2_phi_only.dat case3_phi_only.dat
rm -rf fig_case1 fig_case2 fig_case3

# ===== compile =====
# The module file contains the subroutines via #include,
# so do not compile sub_D03_hypre_3Draz_uniform*.f90 separately.
$FC -O2 -fdefault-real-8 -cpp -o "$EXE" \
    "$SRC_MAIN" \
    -I"${HYPRE_INC}" \
    -L"${HYPRE_LIB}" \
    -Wl,-rpath,"${HYPRE_LIB}" \
    -lHYPRE

# ===== run =====
$RUNNER -n "$NPROC" ./"$EXE"

# ===== plot =====
if [ -f "$PLOT_SCRIPT" ]; then
    if [ -f case1_phi_compare.dat ]; then
        python3 "$PLOT_SCRIPT" --input case1_phi_compare.dat --outdir fig_case1
    fi

    if [ -f case2_phi_only.dat ]; then
        python3 "$PLOT_SCRIPT" --input case2_phi_only.dat --outdir fig_case2
    fi

    if [ -f case3_phi_only.dat ]; then
        python3 "$PLOT_SCRIPT" --input case3_phi_only.dat --outdir fig_case3
    fi
else
    echo "WARNING: plot script $PLOT_SCRIPT not found, skip plotting."
fi

echo "Done."
