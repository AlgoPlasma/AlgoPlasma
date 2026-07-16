#!/bin/bash
set -euo pipefail

export HYPRE_DIR=${HYPRE_DIR:-${HOME}/nfs/hypre/src/hypre}
export HYPRE_LIB=${HYPRE_LIB:-${HYPRE_DIR}/lib}
export LD_LIBRARY_PATH=${HYPRE_LIB}:${LD_LIBRARY_PATH:-}

EXE=${EXE:-./main.out}
NP_LIST=${NP_LIST:-"1 2 4 8 16 24 32 48 64 128"}
OMP_LIST=${OMP_LIST:-"1"}
NREPEAT=${NREPEAT:-5}
WRITE_PHI=${WRITE_PHI:-0}
MPI_BIND_ARGS=${MPI_BIND_ARGS:---bind-to none}

echo "===== Local HYPRE/OpenMPI MPI-rank scan ====="
echo "HYPRE_DIR=${HYPRE_DIR}"
echo "HYPRE_LIB=${HYPRE_LIB}"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH%%:*}"
echo "EXE=${EXE}"
echo "NP_LIST=${NP_LIST}"
echo "OMP_LIST=${OMP_LIST}"
echo "NREPEAT=${NREPEAT}"
echo "WRITE_PHI=${WRITE_PHI}"
echo "MPI_BIND_ARGS=${MPI_BIND_ARGS}"
echo "mpirun=$(which mpirun)"
echo "mpicc=$(which mpicc)"
mpicc -show
ldd ${EXE} | grep -Ei "hypre|mpi|openmpi|gomp|omp" || true

for np in ${NP_LIST}; do
    for nth in ${OMP_LIST}; do
        for r in $(seq 1 ${NREPEAT}); do
            echo "===== local-build, np=${np}, OMP_NUM_THREADS=${nth}, repeat=${r} ====="

            export OMP_NUM_THREADS=${nth}
            export WRITE_PHI

            mpirun -np ${np} \
              ${MPI_BIND_ARGS} \
              --mca pml ob1 \
              --mca btl self,vader,tcp \
              -x OMP_NUM_THREADS \
              -x WRITE_PHI \
              -x HYPRE_DIR \
              -x LD_LIBRARY_PATH \
              ${EXE} | tee run_AMD_np${np}_omp${nth}_${r}.log
        done
    done
done

echo
echo "===== All tests finished ====="
echo "Log files:"
ls -lh run_AMD_np*_omp*_*.log
