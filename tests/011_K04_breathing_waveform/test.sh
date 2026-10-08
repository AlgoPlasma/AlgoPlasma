#!/usr/bin/env bash
set -euo pipefail
case_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "${case_dir}"
export PYTHONDONTWRITEBYTECODE=1
"${PYTHON:-python3}" -B -m unittest discover -s . -v
