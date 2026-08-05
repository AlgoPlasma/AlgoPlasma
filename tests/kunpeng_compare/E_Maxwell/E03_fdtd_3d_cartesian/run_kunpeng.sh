#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

bash "${SCRIPT_DIR}/run_common.sh" kunpeng "$@"
