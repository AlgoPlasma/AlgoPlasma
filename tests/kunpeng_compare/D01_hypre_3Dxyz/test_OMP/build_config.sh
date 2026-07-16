#!/bin/bash

set -e

TOOLCHAIN=${TOOLCHAIN:-gcc}

case "${TOOLCHAIN}" in
    gcc)
        EXE=${EXE:-main_gcc.out}
        ENV_SH=${ENV_SH:-/opt/hypre/3.1.0-gcc/env.sh}
        ;;
    bisheng)
        EXE=${EXE:-main_bisheng.out}
        ENV_SH=${ENV_SH:-/opt/hypre/3.1.0-bisheng/env.sh}
        ;;
    *)
        echo "ERROR: unsupported TOOLCHAIN=${TOOLCHAIN}; use gcc or bisheng." >&2
        exit 1
        ;;
esac

if [ -f "${ENV_SH}" ]; then
    # shellcheck disable=SC1090
    source "${ENV_SH}"
elif [ -z "${HYPRE_INC:-}" ] || [ -z "${HYPRE_LIB:-}" ]; then
    echo "ERROR: ${ENV_SH} not found and HYPRE_INC/HYPRE_LIB are not set." >&2
    echo "Set ENV_SH, or export HYPRE_INC and HYPRE_LIB before running make.sh." >&2
    exit 1
fi

if [ -z "${HYPRE_INC:-}" ] && [ -n "${HYPRE_DIR:-}" ]; then
    HYPRE_INC=${HYPRE_DIR}/include
fi

if [ -z "${HYPRE_LIB:-}" ] && [ -n "${HYPRE_DIR:-}" ]; then
    HYPRE_LIB=${HYPRE_DIR}/lib
fi

if [ -z "${HYPRE_INC:-}" ] || [ -z "${HYPRE_LIB:-}" ]; then
    echo "ERROR: HYPRE_INC and HYPRE_LIB must be set." >&2
    exit 1
fi

if [ -n "${MPI_HOME:-}" ] && [ -x "${MPI_HOME}/bin/mpicc" ]; then
    CC=${CC:-${MPI_HOME}/bin/mpicc}
else
    CC=${CC:-mpicc}
fi

if [ -n "${MPI_HOME:-}" ] && [ -x "${MPI_HOME}/bin/mpif90" ]; then
    FC=${FC:-${MPI_HOME}/bin/mpif90}
else
    FC=${FC:-mpif90}
fi

HYPRE_INCLUDES="-I${HYPRE_INC}"

if [ -n "${HYPRE_SRC:-}" ]; then
    for subdir in struct_ls struct_mv utilities; do
        if [ -d "${HYPRE_SRC}/${subdir}" ]; then
            HYPRE_INCLUDES="${HYPRE_INCLUDES} -I${HYPRE_SRC}/${subdir}"
        fi
    done
fi

if [ -d "${HYPRE_LIB}" ]; then
    export LD_LIBRARY_PATH="${HYPRE_LIB}:${LD_LIBRARY_PATH:-}"
fi

export TOOLCHAIN EXE HYPRE_INC HYPRE_LIB HYPRE_INCLUDES CC FC
