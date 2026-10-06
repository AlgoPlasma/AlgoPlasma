#!/usr/bin/env bash
# Same teaching problem, spatial MPI ownership; OPENMP=0 selects pure MPI.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
SRC="$ROOT/J_Fluid/J02_neutral_sn_transport_2Drz"
BUILD="$HERE/build/mpi"
FLAGS=(-cpp -DJ02_USE_MPI -O2 -fdefault-real-8 -fcheck=all -Wall -Wextra)
case "${OPENMP:-1}" in
    1) FLAGS+=(-fopenmp) ;;
    0) ;;
    *) echo "OPENMP must be 0 or 1" >&2; exit 2 ;;
esac
read -r -a MPI_ARGS <<< "${MPIEXEC_FLAGS:-}"
mkdir -p "$BUILD"
"${MPIFC:-mpifort}" "${FLAGS[@]}" -J"$BUILD" -I"$SRC" \
    "$SRC/mod_J02_neutral_sn_transport_2Drz.f90" "$HERE/sn_channel.f90" -o "$BUILD/sn_channel.out"
OMP_NUM_THREADS="${OMP_NUM_THREADS:-2}" OMP_DYNAMIC=FALSE \
    "${MPIEXEC:-mpiexec}" "${MPI_ARGS[@]}" -np "${MPI_NP:-4}" "$BUILD/sn_channel.out"
