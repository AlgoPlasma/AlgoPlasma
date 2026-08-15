#!/usr/bin/env bash
set -euo pipefail

case_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_hypre_root="$(cd "${case_dir}/../../../hypre/src/hypre" && pwd)"

HYPRE_ROOT="${HYPRE_ROOT:-${default_hypre_root}}"

cmake -S "${case_dir}" -B "${case_dir}/build" \
  -DHYPRE_ROOT="${HYPRE_ROOT}"

cmake --build "${case_dir}/build" --parallel

mkdir -p "${case_dir}/output"
cd "${case_dir}/output"
"${case_dir}/build/two_stream_2d"
python3 "${case_dir}/plot.py"
