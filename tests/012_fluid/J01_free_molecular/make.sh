#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
BUILD="$HERE/build"
SOURCE="$ROOT/J_Fluid/J01_free_molecular"
FC="${FC:-gfortran}"
mkdir -p "$BUILD"
FLAGS=(-cpp -O0 -g -fdefault-real-8 -fcheck=all -fbacktrace
  -finit-real=snan -ffpe-trap=invalid,zero,overflow -Wall -Wextra)
for unit in J01_continuity_freeflow J01_neutral_free_molecular_2Drz; do
  "$FC" "${FLAGS[@]}" -I"$SOURCE" -J"$BUILD" -c "$SOURCE/mod_${unit}.f90" -o "$BUILD/mod_${unit}.o"
done
for source in "$HERE"/source_f90/test_*.f90; do
  name="$(basename "$source" .f90)"
  "$FC" "${FLAGS[@]}" -I"$BUILD" "$source" "$BUILD"/mod_*.o -o "$BUILD/${name}.out"
  echo "Build complete: $BUILD/${name}.out"
done
