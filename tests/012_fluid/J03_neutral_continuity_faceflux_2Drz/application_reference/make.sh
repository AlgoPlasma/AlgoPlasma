#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"
BUILD="$HERE/build/application_reference"
J02="$ROOT/J_Fluid/J02_neutral_sn_transport_2Drz"
J03="$ROOT/J_Fluid/J03_neutral_continuity_faceflux_2Drz"
OPENMP_FLAGS=()
case "${OPENMP:-1}" in
  1) OPENMP_FLAGS=(-fopenmp) ;;
  0) ;;
  *) echo "OPENMP must be 0 or 1" >&2; exit 2 ;;
esac
mkdir -p "$BUILD/j02" "$BUILD/j03"
gfortran -O3 -J"$BUILD/j02" -c "$HERE/../application_case.f90" -o "$BUILD/j02/case.o"
gfortran -O2 -fdefault-real-8 -J"$BUILD/j03" -c "$HERE/../application_case.f90" -o "$BUILD/j03/case.o"

gfortran "${OPENMP_FLAGS[@]}" -O3 -cpp -I"$HERE/.." -Wall -Wextra -Wimplicit-interface \
  -I"$J02" -J"$BUILD/j02" -c "$J02/mod_J02_neutral_sn_transport_2Drz.f90" \
  -o "$BUILD/j02/mod_J02.o"
gfortran "${OPENMP_FLAGS[@]}" -O3 -cpp -I"$HERE/.." -Wall -Wextra -Wimplicit-interface \
  -I"$J02" -I"$BUILD/j02" "$HERE/source_f90/run_J02_application_reference.f90" \
  "$BUILD/j02/mod_J02.o" "$BUILD/j02/case.o" -o "$BUILD/run_J02_application_reference.out"

gfortran -O2 -cpp -I"$HERE/.." -fdefault-real-8 -Wall -Wextra -Wimplicit-interface -fcheck=all \
  -I"$J03" -J"$BUILD/j03" -c "$J03/mod_J03_neutral_continuity_faceflux_2Drz.f90" \
  -o "$BUILD/j03/mod_J03.o"
gfortran -O2 -cpp -I"$HERE/.." -fdefault-real-8 -Wall -Wextra -Wimplicit-interface -fcheck=all \
  -I"$J03" -I"$BUILD/j03" "$HERE/source_f90/run_J03_application_reference.f90" \
  "$BUILD/j03/mod_J03.o" "$BUILD/j03/case.o" -o "$BUILD/run_J03_application_reference.out"
echo "Application-reference drivers built in $BUILD"
