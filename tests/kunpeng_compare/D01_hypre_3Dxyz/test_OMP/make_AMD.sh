#!/bin/bash
set -e

HYPRE_INC=${HYPRE_INC:-${HOME}/nfs/hypre/src/hypre/include}
HYPRE_LIB=${HYPRE_LIB:-${HOME}/nfs/hypre/src/hypre/lib}
D01_DIR=../../../D_Poisson/D01_hypre_3Dxyz

FC=${FC:-mpif90}
CC=${CC:-mpicc}
HYPRE_SRC=${HYPRE_SRC:-${HOME}/nfs/hypre/src}
HYPRE_INCLUDES="-I${HYPRE_INC} -I${HYPRE_SRC}/struct_ls -I${HYPRE_SRC}/struct_mv -I${HYPRE_SRC}/utilities"
FFLAGS="-O3 -fdefault-real-8 -fopenmp -cpp ${HYPRE_INCLUDES} -I${D01_DIR}"
CFLAGS="-O3 -fopenmp -I. ${HYPRE_INCLUDES}"

"${CC}" $CFLAGS -c "${D01_DIR}/fun_D01_hypre_3Dxyz_bc.c"
"${FC}" $FFLAGS -c "${D01_DIR}/mod_D01_hypre_3Dxyz_bc.f90"
"${FC}" $FFLAGS -c main_time.f90

"${FC}" -O3 -fdefault-real-8 -fopenmp -o main.out *.o \
    -L"${HYPRE_LIB}" -lHYPRE -lm -fopenmp

echo "Build complete."
