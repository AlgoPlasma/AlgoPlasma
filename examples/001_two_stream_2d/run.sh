#!/usr/bin/env bash
set -euo pipefail

case_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_hypre_root="/opt/hypre-3.1.0"
HYPRE_ROOT="${HYPRE_ROOT:-${default_hypre_root}}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-8}"
export OMP_PROC_BIND="${OMP_PROC_BIND:-close}"
export OMP_PLACES="${OMP_PLACES:-cores}"

cmake -S "${case_dir}" -B "${case_dir}/build" \
  -DHYPRE_ROOT="${HYPRE_ROOT}"

cmake --build "${case_dir}/build" --parallel

mkdir -p "${case_dir}/output"
cd "${case_dir}/output"
"${case_dir}/build/two_stream_2d"
python3 "${case_dir}/plot.py"
