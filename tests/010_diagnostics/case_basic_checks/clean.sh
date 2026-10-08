#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Only this case's regenerable output; documentation snapshots are retained.
rm -rf -- "${SCRIPT_DIR}/output"
