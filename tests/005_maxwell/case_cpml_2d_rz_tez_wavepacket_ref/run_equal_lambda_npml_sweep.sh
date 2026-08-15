#!/usr/bin/env bash
set -euo pipefail

FC="${FC:-gfortran}"
WAVELENGTHS_MM="${WAVELENGTHS_MM:-8 16 24 36 48}"
KAPPA_MAX="${KAPPA_MAX:-3}"
ALPHA_MAX="${ALPHA_MAX:-0.02}"
PML_M="${PML_M:-3.5}"
PML_R0="${PML_R0:-0.012}"

rm -f ./*.o ./*.mod test_rz_tez_wavepacket_cpml.out

"${FC}" -cpp -O2 -fdefault-real-8 -c ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez.f90
"${FC}" -cpp -O2 -fdefault-real-8 -c ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90
"${FC}" -cpp -O2 -fdefault-real-8 test_rz_tez_wavepacket_cpml.f90 \
  mod_E01_cpml_2d_rz_tez.o mod_E01_fdtd_2d_rz_tez.o \
  -o test_rz_tez_wavepacket_cpml.out

for lambda_mm in ${WAVELENGTHS_MM}; do
  npml="${lambda_mm}"
  outdir="output_lambda${lambda_mm}mm_npml${npml}_equal"
  echo "Running lambda=${lambda_mm} mm, npml=${npml} -> ${outdir}"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  (
    cd "${outdir}"
    ../test_rz_tez_wavepacket_cpml.out "${lambda_mm}" "${npml}" "${KAPPA_MAX}" "${ALPHA_MAX}" "${PML_M}" "${PML_R0}"
    python3 ../plot_results.py
  )
done

python3 summarize_equal_lambda_npml_sweep.py
