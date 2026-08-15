#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

platform="${ALGOPLASMA_PLATFORM:-$(uname -m)}"
bash "${SCRIPT_DIR}/run_common.sh" "${platform}" "$@"
