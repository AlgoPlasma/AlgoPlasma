#!/bin/bash
set -e

ENV_SH=${ENV_SH:-/opt/hypre/3.1.0-gcc/env.sh}
# shellcheck disable=SC1090
source "${ENV_SH}"

EXE=${EXE:-./main_gcc.out}
NP=${NP:-4}
NREPEAT=${NREPEAT:-5}
THREAD_LIST=${THREAD_LIST:-"1 2 4 6 8 10 12 14 16 20 22 24 26 28 30 32 48 64"}

echo "===== GCC/OpenMPI HYPRE test ====="
echo "HYPRE_DIR=${HYPRE_DIR}"
echo "MPI_HOME=${MPI_HOME}"
echo "mpirun=$(which mpirun)"
echo "mpicc=$(which mpicc)"
mpicc -show
ldd ${EXE} | grep -Ei "hypre|mpi|openmpi" || true

for nth in ${THREAD_LIST}; do
    for r in $(seq 1 ${NREPEAT}); do
        echo "===== compiler=gcc, np=${NP}, OMP_NUM_THREADS=${nth}, repeat=${r} ====="

        export OMP_NUM_THREADS=${nth}

        mpirun -np ${NP} \
          --bind-to none \
          --mca pml ob1 \
          --mca btl self,vader,tcp \
          -x OMP_NUM_THREADS \
          -x LD_LIBRARY_PATH \
          ${EXE} | tee run_gcc_np${NP}_omp${nth}_${r}.log
    done
done
