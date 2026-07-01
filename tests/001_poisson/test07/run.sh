#!/bin/bash
set -e

FC=mpif90
RUNNER=mpirun
NPROC=1

HYPRE_INC=/home/wbs/install/hypre/src/hypre/include
HYPRE_LIB=/home/wbs/install/hypre/src/hypre/lib

EXE=test_compare_mms
SRC_MAIN=main_compare_uniform_nonuniform_mms.f90
PLOT_SCRIPT=plot_compare_uniform_nonuniform.py

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

export LD_LIBRARY_PATH="${HYPRE_LIB}:${LD_LIBRARY_PATH}"

rm -f "$EXE" *.o *.mod
rm -f compare_uniform_nonuniform_rz_mms.dat field_uniform_fine.dat field_nonuniform_fine.dat
rm -rf fig_compare_uniform_nonuniform_rz_mms

$FC -O2 -fdefault-real-8 -cpp -o "$EXE" \
    "$SRC_MAIN" \
    -I"${HYPRE_INC}" \
    -L"${HYPRE_LIB}" \
    -Wl,-rpath,"${HYPRE_LIB}" \
    -lHYPRE

$RUNNER -n "$NPROC" ./"$EXE"

if [ -f "$PLOT_SCRIPT" ]; then
    python3 "$PLOT_SCRIPT"
else
    echo "WARNING: plot script not found."
fi

echo "Done."
