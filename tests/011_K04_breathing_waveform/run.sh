#!/usr/bin/env bash
# Run local tests, generate both artificial examples, and draw their figures.
set -euo pipefail
case_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "${case_dir}"
export PYTHONDONTWRITEBYTECODE=1
bash test.sh
"${PYTHON:-python3}" -B source_py/run_example.py
"${PYTHON:-python3}" -B source_py/plot_figures.py
"${PYTHON:-python3}" -B source_py/run_compact_phase.py
"${PYTHON:-python3}" -B source_py/plot_compact_phase.py
