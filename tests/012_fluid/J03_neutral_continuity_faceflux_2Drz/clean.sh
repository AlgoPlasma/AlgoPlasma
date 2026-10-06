#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
rm -rf \
    "${SCRIPT_DIR}/build" \
    "${SCRIPT_DIR}/__pycache__" \
  "${SCRIPT_DIR}/application_reference/build" \
  "${SCRIPT_DIR}/application_reference/__pycache__" \
  "${SCRIPT_DIR}/application_reference_J01/build" \
  "${SCRIPT_DIR}/application_reference_J01/__pycache__"
