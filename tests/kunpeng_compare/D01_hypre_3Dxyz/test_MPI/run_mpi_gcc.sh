#!/bin/bash
set -e

source /opt/hypre/3.1.0-gcc/env.sh

EXE=./main_gcc.out
NP_LIST="1 2 4 8 16 24 32 48 64 128"
OMP_NUM_THREADS=1
NREPEAT=5

echo "===== GCC/OpenMPI HYPRE test ====="
echo "HYPRE_DIR=${HYPRE_DIR}"
echo "MPI_HOME=${MPI_HOME}"
echo "mpirun=$(which mpirun)"
echo "mpicc=$(which mpicc)"
mpicc -show

echo "===== recompile the program"
./make.sh

ldd ${EXE} | grep -Ei "hypre|mpi|openmpi|gomp" || true

for np in ${NP_LIST}; do
    for r in $(seq 1 ${NREPEAT}); do
        echo "===== compiler=gcc, np=${np}, OMP_NUM_THREADS=${OMP_NUM_THREADS}, repeat=${r} ====="

        export OMP_NUM_THREADS=${OMP_NUM_THREADS}

        mpirun -np ${np} \
          --bind-to none \
          --mca pml ob1 \
          --mca btl self,vader,tcp \
          -x OMP_NUM_THREADS \
          -x LD_LIBRARY_PATH \
          ${EXE} | tee run_gcc_np${np}_omp${OMP_NUM_THREADS}_${r}.log
    done
done
