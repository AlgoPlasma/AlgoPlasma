#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <platform> [NX NY NZ NSTEPS REPEATS]" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

ALGOPLASMA_PLATFORM="$1"
shift

NX="${1:-${NX:-96}}"
NY="${2:-${NY:-96}}"
NZ="${3:-${NZ:-96}}"
NSTEPS="${4:-${NSTEPS:-40}}"
REPEATS="${5:-${REPEATS:-3}}"
THREAD_LIST="${THREAD_LIST:-1 2 4 8 16 32 64}"
SAFE_PLATFORM="$(printf '%s' "${ALGOPLASMA_PLATFORM}" | tr -c 'A-Za-z0-9_.-' '_')"

FC="${FC:-gfortran}"
FCFLAGS="${FCFLAGS:--cpp -O3 -fdefault-real-8 -fopenmp -ffree-line-length-none}"
export FC FCFLAGS

OMP_PROC_BIND="${OMP_PROC_BIND:-close}"
OMP_PLACES="${OMP_PLACES:-cores}"
export OMP_PROC_BIND OMP_PLACES

bash "${SCRIPT_DIR}/clean.sh"
bash "${SCRIPT_DIR}/make.sh"

mkdir -p output/logs "data_raw/${SAFE_PLATFORM}"

cpu_model="$(
  awk -F: '
    /model name|Hardware|Processor/ {
      gsub(/^[ \t]+|[ \t]+$/, "", $2)
      if ($2 != "") { print $2; exit }
    }
  ' /proc/cpuinfo 2>/dev/null || true
)"
cpu_model="${cpu_model:-unknown}"
compiler="$("${FC}" --version | head -n 1)"
hostname_value="$(hostname 2>/dev/null || echo unknown)"

csv_escape() {
  local value="${1//\"/\"\"}"
  printf '"%s"' "${value}"
}

raw_csv="output/key_metrics_raw.csv"
repeat_csv="output/timing_repeats.csv"

echo "platform,hostname,cpu_model,compiler,fc,fcflags,omp_proc_bind,omp_places,nx,ny,nz,nsteps,repeats,threads,cells_per_step,total_component_updates,avg_s,best_s,worst_s,component_updates_per_s,checksum_e,checksum_h,total_energy" > "${raw_csv}"
echo "platform,threads,repeat,elapsed_s,component_updates_per_s,checksum_e,checksum_h,total_energy" > "${repeat_csv}"

echo "Running E03 FDTD Cartesian thread sweep..."
echo "platform=${ALGOPLASMA_PLATFORM}, nx=${NX}, ny=${NY}, nz=${NZ}, nsteps=${NSTEPS}, repeats=${REPEATS}"
echo "THREAD_LIST=${THREAD_LIST}"
echo "OMP_PROC_BIND=${OMP_PROC_BIND}, OMP_PLACES=${OMP_PLACES}"

for nthread in ${THREAD_LIST}; do
  export OMP_NUM_THREADS="${nthread}"
  log_path="output/logs/${SAFE_PLATFORM}_threads_${nthread}.log"

  echo "--- threads=${nthread} ---"
  ./build/e03_fdtd_3d_cartesian_bench.out \
    "${NX}" "${NY}" "${NZ}" "${NSTEPS}" "${REPEATS}" \
    | tee "${log_path}"

  summary_line="$(grep '^SUMMARY_CSV,' "${log_path}" | tail -n 1 || true)"
  if [[ -z "${summary_line}" ]]; then
    echo "ERROR: benchmark did not emit SUMMARY_CSV for threads=${nthread}" >&2
    exit 1
  fi

  summary_payload="${summary_line#SUMMARY_CSV,}"
  {
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
      "$(csv_escape "${ALGOPLASMA_PLATFORM}")" \
      "$(csv_escape "${hostname_value}")" \
      "$(csv_escape "${cpu_model}")" \
      "$(csv_escape "${compiler}")" \
      "$(csv_escape "${FC}")" \
      "$(csv_escape "${FCFLAGS}")" \
      "$(csv_escape "${OMP_PROC_BIND}")" \
      "$(csv_escape "${OMP_PLACES}")" \
      "${summary_payload}"
  } >> "${raw_csv}"

  awk -F, -v platform="${ALGOPLASMA_PLATFORM}" -v threads="${nthread}" 'NR > 1 {
    print platform "," threads "," $0
  }' output/timings.csv >> "${repeat_csv}"
done

python3 source_py/analyze_scaling.py "${raw_csv}" output/key_metrics.csv

rm -rf "data_raw/${SAFE_PLATFORM}/logs"
mkdir -p "data_raw/${SAFE_PLATFORM}"
cp output/key_metrics.csv "data_raw/${SAFE_PLATFORM}/key_metrics.csv"
cp output/key_metrics_raw.csv "data_raw/${SAFE_PLATFORM}/key_metrics_raw.csv"
cp output/timing_repeats.csv "data_raw/${SAFE_PLATFORM}/timing_repeats.csv"
cp output/build_info.txt "data_raw/${SAFE_PLATFORM}/build_info.txt"
cp -r output/logs "data_raw/${SAFE_PLATFORM}/logs"

echo "Wrote output/key_metrics.csv"
echo "Copied comparable files to data_raw/${SAFE_PLATFORM}/"
