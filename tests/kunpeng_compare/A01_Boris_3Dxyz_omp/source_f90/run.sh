#!/bin/bash

cd build || exit 1

for t in 8 16 32 64 128 256 512
do
    echo "Running with OMP_NUM_THREADS=$t ..."
    OMP_NUM_THREADS=$t ./a.out > "log${t}.run" 2>&1
    echo "Finished OMP_NUM_THREADS=$t"
done
