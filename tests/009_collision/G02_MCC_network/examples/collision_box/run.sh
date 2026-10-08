#!/bin/sh
set -eu

example_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$example_dir/../../../../.." && pwd)
build_dir=${COLLISION_BOX_BUILD_DIR:-/tmp/g02_collision_box_build}
output_dir=${1:-"$example_dir/results"}
if [ "$#" -gt 0 ]; then
    shift
fi

cmake -S "$repo_root/tests/009_collision/G02_MCC_network" -B "$build_dir" -DCMAKE_BUILD_TYPE=Release \
    -DG02_MCC_BUILD_TESTS=ON \
    -DG02_MCC_ENABLE_OPENMP="${G02_MCC_ENABLE_OPENMP:-OFF}"
cmake --build "$build_dir" --target collision_box -j 4
"$build_dir/collision_box/collision_box" \
    --output "$output_dir" "$@"
python3 "$example_dir/plot.py" "$output_dir"
