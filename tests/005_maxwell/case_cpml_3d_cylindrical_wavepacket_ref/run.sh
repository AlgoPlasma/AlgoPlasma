#!/usr/bin/env bash
set -euo pipefail

FC="${FC:-gfortran}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_MM="${1:-18}"
OUTPUT_DIR="${2:-}"
NPML="${3:-12}"
KAPPA_MAX="${4:-3}"
ALPHA_MAX="${5:-0.02}"
PML_M="${6:-3.5}"
PML_R0="${7:-0.012}"
CASE_FILTER="${8:-all}"
SIGMA_LONG_MM="${9:-18}"
N_LONG_INTERIOR="${10:-136}"
PACKET_MARGIN_MM="${11:-36}"
NSTEP="${12:-450}"
LATE_GATE="${13:-260}"
REF_EXTRA="${14:-200}"
SNAPSHOT_STRIDE="${15:-0}"

cd "${ROOT_DIR}"
rm -f ./*.o ./*.mod test_3d_cylindrical_wavepacket_cpml.out

"${FC}" -cpp -O2 -fdefault-real-8 -c ../../../E_Maxwell/E02_Maxwell_3Drtz/mod_E02_cpml_3d_cylindrical.f90
"${FC}" -cpp -O2 -fdefault-real-8 -c ../../../E_Maxwell/E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical.f90
"${FC}" -cpp -O2 -fdefault-real-8 test_3d_cylindrical_wavepacket_cpml.f90 \
  mod_E02_cpml_3d_cylindrical.o mod_E02_fdtd_3d_cylindrical.o \
  -o test_3d_cylindrical_wavepacket_cpml.out

if [[ -n "${OUTPUT_DIR}" ]]; then
  mkdir -p "${OUTPUT_DIR}"
  (
    cd "${OUTPUT_DIR}"
    "${ROOT_DIR}/test_3d_cylindrical_wavepacket_cpml.out" \
      "${LAMBDA_MM}" "${NPML}" "${KAPPA_MAX}" "${ALPHA_MAX}" "${PML_M}" "${PML_R0}" \
      "${CASE_FILTER}" "${SIGMA_LONG_MM}" "${N_LONG_INTERIOR}" "${PACKET_MARGIN_MM}" \
      "${NSTEP}" "${LATE_GATE}" "${REF_EXTRA}" "${SNAPSHOT_STRIDE}"
    if [[ "${CASE_FILTER}" == "all" ]]; then
      python3 "${ROOT_DIR}/plot_results.py"
    fi
    if [[ "${SNAPSHOT_STRIDE}" != "0" ]]; then
      python3 "${ROOT_DIR}/make_gifs.py"
    fi
  )
else
  ./test_3d_cylindrical_wavepacket_cpml.out \
    "${LAMBDA_MM}" "${NPML}" "${KAPPA_MAX}" "${ALPHA_MAX}" "${PML_M}" "${PML_R0}" \
    "${CASE_FILTER}" "${SIGMA_LONG_MM}" "${N_LONG_INTERIOR}" "${PACKET_MARGIN_MM}" \
    "${NSTEP}" "${LATE_GATE}" "${REF_EXTRA}" "${SNAPSHOT_STRIDE}"
  if [[ "${CASE_FILTER}" == "all" ]]; then
    python3 plot_results.py
  fi
  if [[ "${SNAPSHOT_STRIDE}" != "0" ]]; then
    python3 make_gifs.py
  fi
fi
