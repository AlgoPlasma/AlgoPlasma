#!/usr/bin/env bash
set -euo pipefail

FC="${FC:-gfortran}"
WAVELENGTHS_MM="${WAVELENGTHS_MM:-6 8 10 12 14 16 24 36}"

rm -f ./*.o ./*.mod test_rz_tez_wavepacket_cpml.out

"${FC}" -cpp -O2 -fdefault-real-8 -c ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez.f90
"${FC}" -cpp -O2 -fdefault-real-8 -c ../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90
"${FC}" -cpp -O2 -fdefault-real-8 test_rz_tez_wavepacket_cpml.f90 \
  mod_E01_cpml_2d_rz_tez.o mod_E01_fdtd_2d_rz_tez.o \
  -o test_rz_tez_wavepacket_cpml.out

for lambda_mm in ${WAVELENGTHS_MM}; do
  outdir="output_lambda${lambda_mm}mm"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"
  echo "Running lambda=${lambda_mm} mm -> ${outdir}"
  (
    cd "${outdir}"
    ../test_rz_tez_wavepacket_cpml.out "${lambda_mm}"
    python3 ../plot_results.py
  )
done

python3 summarize_wavelength_sweep.py
