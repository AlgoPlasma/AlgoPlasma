#!/bin/bash
set -e

export HYPRE_DIR=${HYPRE_DIR:-${HOME}/nfs/hypre/src/hypre}
export HYPRE_LIB=${HYPRE_LIB:-${HYPRE_DIR}/lib}
export LD_LIBRARY_PATH=${HYPRE_LIB}:$LD_LIBRARY_PATH

EXE=${EXE:-./main.out}
NP=${NP:-4}
NREPEAT=${NREPEAT:-5}
THREAD_LIST=${THREAD_LIST:-"1 2 4 6 8 10 12 14 16 20 22 24 26 28 30 32 48 64"}

echo "===== Local HYPRE/OpenMPI test ====="
echo "HYPRE_DIR=${HYPRE_DIR}"
echo "HYPRE_LIB=${HYPRE_LIB}"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH%%:*}"
echo "mpirun=$(which mpirun)"
echo "mpicc=$(which mpicc)"
mpicc -show
ldd ${EXE} | grep -Ei "hypre|mpi|openmpi" || true

for nth in ${THREAD_LIST}; do
    for r in $(seq 1 ${NREPEAT}); do
        echo "===== local-build, np=${NP}, OMP_NUM_THREADS=${nth}, repeat=${r} ====="

        export OMP_NUM_THREADS=${nth}

        mpirun -np ${NP} \
          --bind-to none \
          --mca pml ob1 \
          --mca btl self,vader,tcp \
          -x OMP_NUM_THREADS \
          -x LD_LIBRARY_PATH \
          ${EXE} | tee run_AMD_np${NP}_omp${nth}_${r}.log
    done
done

echo -e "\n===== All tests finished ====="
echo "Log files:"
ls -lh run_AMD_np${NP}_omp*_*.log
