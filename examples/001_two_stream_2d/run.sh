#!/usr/bin/env bash
set -euo pipefail

case_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmake -S "${case_dir}" -B "${case_dir}/build"
cmake --build "${case_dir}/build" --parallel
mkdir -p "${case_dir}/output"
cd "${case_dir}/output"
"${case_dir}/build/two_stream_2d"
python3 "${case_dir}/plot.py"

