#!/bin/bash

# Choose toolchain: gcc or bisheng
TOOLCHAIN=${TOOLCHAIN:-gcc}

if [ "$TOOLCHAIN" = "gcc" ]; then
    source /opt/hypre/3.1.0-gcc/env.sh

    EXE=${EXE:-main_gcc.out}
    CC=/usr/bin/mpicc
    FC=/usr/bin/mpifort

elif [ "$TOOLCHAIN" = "bisheng" ]; then
    source /opt/hypre/3.1.0-bisheng/env.sh

    EXE=${EXE:-main_bisheng.out}
    CC=/opt/openmpi/4.1.4-bisheng/bin/mpicc
    FC=/opt/openmpi/4.1.4-bisheng/bin/mpifort

else
    echo "ERROR: TOOLCHAIN must be gcc or bisheng"
    exit 1
fi

HYPRE_INC=${HYPRE_DIR}/include
HYPRE_LIB=${HYPRE_DIR}/lib
HYPRE_INCLUDES="-I${HYPRE_INC}"

export LD_LIBRARY_PATH=${HYPRE_LIB}:${LD_LIBRARY_PATH}
