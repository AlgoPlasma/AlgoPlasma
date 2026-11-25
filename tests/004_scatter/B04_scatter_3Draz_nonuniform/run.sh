#!/usr/bin/env bash
set -euo pipefail
case_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$case_dir/../../.." && pwd)"
compiler="${FC:-gfortran}"
precision="${1:-double}"
mode="${2:-debug}"
flags=(-cpp -std=f2008 -Wall -Wextra -Wno-compare-reals -fimplicit-none)
case "$precision" in
    double) flags+=(-fdefault-real-8) ;;
    single) ;;
    *) echo "Usage: bash run.sh [double|single] [debug|release]" >&2; exit 2 ;;
esac
case "$mode" in
    debug) flags+=(-O0 -g -fcheck=all -ffpe-trap=invalid,zero,overflow -fbacktrace) ;;
    release) flags+=(-O2) ;;
    *) echo "Usage: bash run.sh [double|single] [debug|release]" >&2; exit 2 ;;
esac
build_dir="$case_dir/build/$precision-$mode"
mkdir -p "$build_dir"
b04="$repo_dir/B_Scatter/B04_scatter_3Draz_nonuniform"
b02="$repo_dir/B_Scatter/B02_deposit_3d_cyl"
"$compiler" "${flags[@]}" -J "$build_dir" -I "$build_dir" -I "$b04" -I "$b02" \
    "$b04/mod_B04_scatter_3Draz_nonuniform.f90" \
    "$b02/mod_B02_deposit_charge_3d_cyl.f90" \
    "$case_dir/source_f90/main.f90" -o "$build_dir/test_b04"
"$build_dir/test_b04" "$build_dir"
