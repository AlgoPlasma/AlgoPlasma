#!/bin/bash
set -e

source ./build_config.sh

# test00 source path
D01_DIR=../../../D_Poisson/D01_hypre_3Dxyz

FFLAGS="-O3 -fdefault-real-8 -fopenmp -cpp ${HYPRE_INCLUDES} -I${D01_DIR}"
CFLAGS="-O3 -fopenmp -I. ${HYPRE_INCLUDES}"

echo "===== Build configuration ====="
echo "TOOLCHAIN   = ${TOOLCHAIN}"
echo "EXE         = ${EXE}"
echo "D01_DIR     = ${D01_DIR}"
echo "HYPRE_DIR   = ${HYPRE_DIR}"
echo "HYPRE_INC   = ${HYPRE_INC}"
echo "HYPRE_LIB   = ${HYPRE_LIB}"
echo "MPI_HOME    = ${MPI_HOME}"
echo "CC          = ${CC}"
echo "FC          = ${FC}"

echo "===== Compiler wrappers ====="
ls -l "${CC}"
ls -l "${FC}"
"${CC}" -show
"${FC}" -show

echo "===== Clean old objects ====="
rm -f *.o *.mod main.out main_gcc.out main_bisheng.out

echo "===== Compile D01 C interface ====="
"${CC}" ${CFLAGS} -c "${D01_DIR}/fun_D01_hypre_3Dxyz_bc.c"

echo "===== Compile D01 Fortran module ====="
"${FC}" ${FFLAGS} -c "${D01_DIR}/mod_D01_hypre_3Dxyz_bc.f90"

echo "===== Compile main_time.f90 ====="
"${FC}" ${FFLAGS} -c main_time.f90

echo "===== Link ${EXE} ====="
"${FC}" -O3 -fdefault-real-8 -fopenmp -o "${EXE}" *.o \
    -L"${HYPRE_LIB}" -lHYPRE -lm -fopenmp

ln -sf "${EXE}" main.out

echo "===== Linked libraries ====="
ldd "${EXE}" | grep -Ei "hypre|mpi|openmpi|gfortran|flang|clang" || true

echo "Build complete: ${EXE}"
echo "main.out -> ${EXE}"
