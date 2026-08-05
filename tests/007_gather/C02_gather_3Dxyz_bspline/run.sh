#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

bash clean.sh
bash make.sh

mkdir -p output
./build/main
python3 source_py/analyze.py
