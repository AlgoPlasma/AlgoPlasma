#!/usr/bin/env bash
# Remove compile artifacts only. Logs in data_raw/ and post-processing
# results in output/ are preserved.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

rm -rf source_f90/build

echo "Removed source_f90/build (kept data_raw/ and output/)."
