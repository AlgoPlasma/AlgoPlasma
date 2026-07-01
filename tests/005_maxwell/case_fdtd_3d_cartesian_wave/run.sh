#!/usr/bin/env bash
set -euo pipefail

python3 fdtd_3d_cartesian_wave.py
echo "Generated: fdtd_3d_cartesian_ez_slices.png"
