#!/usr/bin/env bash

init_fortran_env() {
  FC="${FC:-gfortran}"
  FCFLAGS=(-cpp -O2 -fdefault-real-8 -fopenmp)
  FCLDFLAGS=(-O2 -fdefault-real-8 -fopenmp)
}

fc_compile() {
  "${FC}" "${FCFLAGS[@]}" -c "$1"
}

fc_compile_many() {
  local src
  for src in "$@"; do
    fc_compile "${src}"
  done
}

fc_link() {
  local exe="$1"
  shift
  "${FC}" "${FCLDFLAGS[@]}" -o "${exe}" "$@"
}

run_case_and_capture_summary() {
  local exe="$1"
  local log_path="$2"
  local summary_file="$3"
  local fallback="$4"
  shift 4

  "./${exe}.out" "$@" | tee "${log_path}"

  local summary_line
  summary_line="$(grep '^SUMMARY_CSV,' "${log_path}" | tail -1 || true)"
  if [[ -n "${summary_line}" ]]; then
    echo "${summary_line#SUMMARY_CSV,}" >> "${summary_file}"
  else
    echo "${fallback}" >> "${summary_file}"
  fi
}
