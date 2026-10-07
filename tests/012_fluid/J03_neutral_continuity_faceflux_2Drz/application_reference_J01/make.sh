#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"
BUILD="$HERE/build"
J01="$ROOT/J_Fluid/J01_free_molecular"
J03="$ROOT/J_Fluid/J03_neutral_continuity_faceflux_2Drz"
mkdir -p "$BUILD/j01_mod" "$BUILD/j03_mod"
gfortran -O3 -fdefault-real-8 -J"$BUILD/j01_mod" -c "$HERE/../application_case.f90" -o "$BUILD/j01_mod/case.o"
gfortran -O3 -fdefault-real-8 -J"$BUILD/j03_mod" -c "$HERE/../application_case.f90" -o "$BUILD/j03_mod/case.o"
gfortran -O3 -cpp -I"$HERE/.." -fdefault-real-8 -Wall -Wextra -Wimplicit-interface \
  -I"$J01" -J"$BUILD/j01_mod" -c "$J01/mod_J01_neutral_free_molecular_2Drz.f90" -o "$BUILD/j01_mod/mod.o"
gfortran -O3 -cpp -I"$HERE/.." -fdefault-real-8 -Wall -Wextra -Wimplicit-interface \
  -I"$J01" -I"$BUILD/j01_mod" "$HERE/source_f90/run_J01_application_reference.f90" \
  "$BUILD/j01_mod/mod.o" "$BUILD/j01_mod/case.o" -o "$BUILD/run_J01_application_reference.out"
gfortran -O3 -cpp -I"$HERE/.." -fdefault-real-8 -Wall -Wextra -Wimplicit-interface \
  -I"$J03" -J"$BUILD/j03_mod" -c "$J03/mod_J03_neutral_continuity_faceflux_2Drz.f90" -o "$BUILD/j03_mod/mod.o"
gfortran -O3 -cpp -I"$HERE/.." -fdefault-real-8 -Wall -Wextra -Wimplicit-interface \
  -I"$J03" -I"$BUILD/j03_mod" "$HERE/source_f90/run_J03_from_J01_reference.f90" \
  "$BUILD/j03_mod/mod.o" "$BUILD/j03_mod/case.o" -o "$BUILD/run_J03_from_J01_reference.out"
echo "J01 -> J03 application drivers built in $BUILD"
