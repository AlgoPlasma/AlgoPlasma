#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PYTHONDONTWRITEBYTECODE=1
export OPENBLAS_NUM_THREADS=1
bash "${SCRIPT_DIR}/clean.sh"
python3 "${SCRIPT_DIR}/source_py/report.py" "$@"
