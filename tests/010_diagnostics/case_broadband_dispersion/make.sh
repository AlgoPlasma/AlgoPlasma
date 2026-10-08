#!/usr/bin/env bash
# Generate the synthetic two-probe records into build/.
# Nothing is shipped with the repository: the signals are rebuilt from the
# constants in source_py/config.py and removed again by clean.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

# The library units under K_Diagnostics/ are imported, so Python would write a
# __pycache__ next to each of them.  Those directories are outside this case and
# clean.sh cannot reach them, so bytecode writing is disabled instead.
export PYTHONDONTWRITEBYTECODE=1

mkdir -p build
python3 source_py/generate.py
