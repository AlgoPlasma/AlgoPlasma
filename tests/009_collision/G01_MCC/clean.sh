#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

if [[ -d "${BUILD_DIR}" ]]; then
  rm -r "${BUILD_DIR}"
fi
