#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

rm -rf build
rm -rf output
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
