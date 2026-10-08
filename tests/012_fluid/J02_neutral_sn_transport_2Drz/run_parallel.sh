#!/usr/bin/env bash
# Isolated from normal unit builds and from B0/ION application outputs.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SRC="$ROOT/J_Fluid/J02_neutral_sn_transport_2Drz"
BUILD="$HERE/build/parallel"
FC="${FC:-gfortran}"
BASE=(-cpp -O2 -std=f2008 -fcheck=all -fbacktrace
      -ffpe-trap=invalid,zero,overflow -Wall -Wextra)
for bytes in 4 8; do
    dir="$BUILD/r$bytes"
    flags=("${BASE[@]}")
    if [[ "$bytes" == 8 ]]; then flags+=(-fdefault-real-8); fi
    for mode in serial openmp; do
        mkdir -p "$dir/$mode"
        extra=()
        if [[ "$mode" == openmp ]]; then extra=(-fopenmp); fi
        "$FC" "${flags[@]}" "${extra[@]}" -I"$SRC" -J"$dir/$mode" \
            -c "$SRC/mod_J02_neutral_sn_transport_2Drz.f90" -o "$dir/$mode/module.o"
        "$FC" "${flags[@]}" "${extra[@]}" -I"$dir/$mode" -J"$dir/$mode" \
            "$HERE/source_f90/test_J02_parallel.f90" "$dir/$mode/module.o" -o "$dir/$mode/test.out"
    done
    "$dir/serial/test.out" "$dir/serial.dat" > "$dir/serial.log"
    for threads in 1 2 4; do
        for repeat in 1 2 3; do
            name="openmp-$threads-$repeat"
            OMP_NUM_THREADS="$threads" OMP_DYNAMIC=FALSE OMP_THREAD_LIMIT="$threads" \
                "$dir/openmp/test.out" "$dir/$name.dat" > "$dir/$name.log"
            if ! grep -q "^\[J02\] sweep workers: $threads$" "$dir/$name.log"; then
                echo "FAIL: solver did not use the requested OpenMP team ($threads workers)" >&2
                exit 1
            fi
            cmp "$dir/serial.dat" "$dir/$name.dat"
        done
        echo "PASS: real$bytes serial/OpenMP ($threads workers, 3 repeats), identical records"
    done
done
# Existing numerical tests use real8 tolerances. Run every one in both builds.
for source in "$HERE/source_f90"/test_*.f90; do
    name="$(basename "$source" .f90)"
    if [[ "$name" == test_J02_parallel || "$name" == test_J02_mpi ]]; then continue; fi
    for mode in serial openmp; do
        dir="$BUILD/r8/$mode"
        extra=()
        if [[ "$mode" == openmp ]]; then extra=(-fopenmp); fi
        "$FC" "${BASE[@]}" -fdefault-real-8 "${extra[@]}" -I"$dir" -J"$dir" \
            "$source" "$dir/module.o" -o "$dir/$name.out"
        if ! OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE OMP_THREAD_LIMIT=4 \
            "$dir/$name.out" > "$dir/$name.log" 2>&1; then
            cat "$dir/$name.log"
            exit 1
        fi
    done
    echo "PASS: $name (serial and OpenMP)"
done
echo "RESULT: PASS"
