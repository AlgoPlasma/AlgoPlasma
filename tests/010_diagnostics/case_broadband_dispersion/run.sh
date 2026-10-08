#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

# The library units under K_Diagnostics/ are imported, so Python would write a
# __pycache__ next to each of them.  Those directories are outside this case and
# clean.sh cannot reach them, so bytecode writing is disabled instead.
export PYTHONDONTWRITEBYTECODE=1

python3 source_py/test_acceptance.py
bash clean.sh
bash make.sh

mkdir -p output/figures
python3 source_py/analyze.py "$@"
