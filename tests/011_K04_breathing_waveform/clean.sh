#!/usr/bin/env bash
# Remove only K04 test-case generated results and Python caches, including ignored files.
set -euo pipefail

if [[ $# -ne 0 ]]; then
    echo "Usage: bash tests/011_K04_breathing_waveform/clean.sh" >&2
    exit 2
fi

unit_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -z "${unit_dir}" || "${unit_dir}" == "/" ||
      ! -f "${unit_dir}/test_K04_breathing_waveform.py" ]]; then
    echo "Refusing to clean: the script is not inside the K04 test case." >&2
    exit 1
fi

# Fixed child path; rm removes an output symlink itself, not its target.
rm -rf -- "${unit_dir}/output"
# find does not follow symlinks. Never traverse a linked external directory.
find "${unit_dir}" -type d -name '__pycache__' -prune -exec rm -rf -- {} +
echo "Removed K04 test-case output/ and __pycache__/ directories."
