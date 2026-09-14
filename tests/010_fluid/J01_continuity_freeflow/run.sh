#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

bash clean.sh
bash make.sh
./build/test_J01_continuity_freeflow.out | tee build/test_J01_continuity_freeflow.log

