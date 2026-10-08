#!/usr/bin/env bash
# Spatial MPI and MPI+OpenMP checks; never touches application output directories.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SRC="$ROOT/J_Fluid/J02_neutral_sn_transport_2Drz"
BUILD="$HERE/build/mpi"
FC="${MPIFC:-mpifort}"
LAUNCHER="${MPIEXEC:-mpiexec}"
read -r -a MPI_ARGS <<< "${MPIEXEC_FLAGS:-}"
BASE=(-cpp -DJ02_USE_MPI -O2 -std=f2008 -fcheck=all -fbacktrace
      -ffpe-trap=invalid,zero,overflow -Wall -Wextra)
command -v "$FC" >/dev/null
command -v "$LAUNCHER" >/dev/null
for bytes in 4 8; do
    for mode in mpi hybrid; do
        dir="$BUILD/r$bytes/$mode"
        mkdir -p "$dir"
        flags=("${BASE[@]}")
        if [[ "$bytes" == 8 ]]; then flags+=(-fdefault-real-8); fi
        if [[ "$mode" == hybrid ]]; then flags+=(-fopenmp); fi
        "$FC" "${flags[@]}" -I"$SRC" -J"$dir" -c "$SRC/mod_J02_neutral_sn_transport_2Drz.f90" -o "$dir/module.o"
        "$FC" "${flags[@]}" -I"$dir" -J"$dir" "$HERE/source_f90/test_J02_mpi.f90" "$dir/module.o" -o "$dir/test.out"
        workers=(1)
        if [[ "$mode" == hybrid ]]; then workers=(2 4); fi
        for layout in 1x1 2x1 1x2 2x2 3x1 1x3; do
            nr="${layout%x*}"
            nz="${layout#*x}"
            ranks=$((nr*nz))
            for threads in "${workers[@]}"; do
                for repeat in 1 2; do
                    log="$dir/${layout}-t${threads}-${repeat}.log"
                    if ! OMP_NUM_THREADS="$threads" OMP_DYNAMIC=FALSE OMP_THREAD_LIMIT="$threads" \
                        timeout "${MPI_TEST_TIMEOUT:-90}s" "$LAUNCHER" "${MPI_ARGS[@]}" -np "$ranks" \
                        "$dir/test.out" "$nr" "$nz" >"$log" 2>&1; then
                        cat "$log"
                        exit 1
                    fi
                    grep -q 'RESULT: PASS' "$log"
                    grep -q "^\[J02\] sweep workers: $threads$" "$log"
                done
                echo "PASS: real$bytes $mode, $layout spatial blocks x $threads workers, 2 repeats"
            done
        done
        log="$dir/custom-2x2.log"
        if ! OMP_NUM_THREADS=1 OMP_DYNAMIC=FALSE OMP_THREAD_LIMIT=1 \
            timeout "${MPI_TEST_TIMEOUT:-90}s" "$LAUNCHER" "${MPI_ARGS[@]}" -np 4 \
            "$dir/test.out" 2 2 custom >"$log" 2>&1; then
            cat "$log"
            exit 1
        fi
        grep -q 'RESULT: PASS' "$log"
        echo "PASS: real$bytes $mode, caller-supplied unequal blocks and reordered communicator"
    done
done
echo "RESULT: PASS"
