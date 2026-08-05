#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Refresh the home-page hero image URL so replacing the PNG is visible after rebuild.
python3 "${SCRIPT_DIR}/scripts/update_home_hero.py"
make -C "${SCRIPT_DIR}" html SPHINXBUILD="${SPHINXBUILD:-python3 -m sphinx}" O="-j auto -Q"
