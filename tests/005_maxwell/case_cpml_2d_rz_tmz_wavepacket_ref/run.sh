#!/usr/bin/env bash
set -euo pipefail

FC="${FC:-gfortran}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_MM="${1:-12}"
OUTPUT_DIR="${2:-}"
NPML="${3:-14}"
KAPPA_MAX="${4:-3}"
ALPHA_MAX="${5:-0.02}"
PML_M="${6:-3.5}"
PML_R0="${7:-0.012}"
CASE_FILTER="${8:-all}"
N_INTERIOR="${9:-136}"
PACKET_MARGIN_MM="${10:-36}"
NSTEP="${11:-450}"
LATE_GATE="${12:-260}"
REF_EXTRA="${13:-200}"
SNAPSHOT_STRIDE="${14:-0}"

cd "${ROOT_DIR}"
rm -f ./*.o ./*.mod test_rz_tmz_wavepacket_cpml.out

"${FC}" -cpp -O2 -fdefault-real-8 -c ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tmz.f90
"${FC}" -cpp -O2 -fdefault-real-8 -c ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz.f90
"${FC}" -cpp -O2 -fdefault-real-8 test_rz_tmz_wavepacket_cpml.f90 \
  mod_E01_cpml_2d_rz_tmz.o mod_E01_fdtd_2d_rz_tmz.o \
  -o test_rz_tmz_wavepacket_cpml.out

if [[ -n "${OUTPUT_DIR}" ]]; then
  mkdir -p "${OUTPUT_DIR}"
  (
    cd "${OUTPUT_DIR}"
    "${ROOT_DIR}/test_rz_tmz_wavepacket_cpml.out" \
      "${LAMBDA_MM}" "${NPML}" "${KAPPA_MAX}" "${ALPHA_MAX}" "${PML_M}" "${PML_R0}" \
      "${CASE_FILTER}" "${N_INTERIOR}" "${PACKET_MARGIN_MM}" "${NSTEP}" "${LATE_GATE}" "${REF_EXTRA}" \
      "${SNAPSHOT_STRIDE}"
    if [[ "${CASE_FILTER}" == "all" ]]; then
      python3 "${ROOT_DIR}/plot_results.py"
    fi
  )
else
  ./test_rz_tmz_wavepacket_cpml.out \
    "${LAMBDA_MM}" "${NPML}" "${KAPPA_MAX}" "${ALPHA_MAX}" "${PML_M}" "${PML_R0}" \
    "${CASE_FILTER}" "${N_INTERIOR}" "${PACKET_MARGIN_MM}" "${NSTEP}" "${LATE_GATE}" "${REF_EXTRA}" \
    "${SNAPSHOT_STRIDE}"
  if [[ "${CASE_FILTER}" == "all" ]]; then
    python3 plot_results.py
  fi
fi
