#!/usr/bin/env bash
# Run the B01 scatter OMP sweep benchmark on the AMD server.
# Cleans, builds, runs, and writes the log straight into data_raw/from_AMD/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/data_raw/from_AMD"
mkdir -p "${LOG_DIR}"

cd "${SCRIPT_DIR}/source_f90"
bash clean.sh
bash make.sh

# The upstream kernel firstprivatizes the (3,np) particle array onto each
# thread's stack; default 8 MB stack overflows at np=1e7. Raise both stacks.
ulimit -s unlimited
export OMP_STACKSIZE=1G

cd build
echo "Running B01 scatter OMP sweep on AMD server ..."
./a.out > "${LOG_DIR}/log.run" 2>&1
echo "Wrote ${LOG_DIR}/log.run"
