#!/usr/bin/env bash
set -euo pipefail

FC="${FC:-h5pfc}"
MPI_RUN="${MPI_RUN:-mpirun}"
MPI_COUNTS="${MPI_COUNTS:-1 2 4 8 16 32 64}"
TOTAL_PARTICLES="${TOTAL_PARTICLES:-4000000}"
NREPEAT="${NREPEAT:-3}"
NVAR="${NVAR:-12}"
PRECISION="${PRECISION:-single}"

fcflags=(-cpp -DUSE_HDF5=1 -O2 -J .)
ldflags=(-O2)
case "${PRECISION}" in
  single|real4|4)
    ;;
  double|real8|8)
    fcflags+=(-fdefault-real-8)
    ldflags+=(-fdefault-real-8)
    ;;
  *)
    echo "ERROR: PRECISION must be single or double, got: ${PRECISION}" >&2
    exit 1
    ;;
esac

read -r -a mpi_extra_args <<< "${MPI_EXTRA_ARGS:-}"

rm -f ./*.o ./*.mod benchmark_F_IO_mpi benchmark_results.csv run_np*.log

"${FC}" "${fcflags[@]}" -c ../../../F_IO/F01_par_load/mod_F01_par_load.f90
"${FC}" "${fcflags[@]}" -c ../../../F_IO/F02_par_output/mod_F02_par_output.f90
"${FC}" "${fcflags[@]}" -I . -c benchmark_F_IO_mpi.f90
"${FC}" "${ldflags[@]}" ./*.o -o benchmark_F_IO_mpi

echo "format,ranks,nvar,np_per_rank,total_particles,real_bytes,payload_MB,write_seconds,read_seconds,write_MB_s,read_MB_s,max_abs_diff" > benchmark_results.csv

for nproc in ${MPI_COUNTS}; do
  if (( TOTAL_PARTICLES % nproc != 0 )); then
    echo "ERROR: TOTAL_PARTICLES=${TOTAL_PARTICLES} is not divisible by MPI ranks=${nproc}" >&2
    exit 1
  fi
  np_per_rank=$(( TOTAL_PARTICLES / nproc ))
  rm -rf B_dat B_bin B_h5
  echo "Running ${nproc} MPI ranks, np_per_rank=${np_per_rank}, total_particles=${TOTAL_PARTICLES}, precision=${PRECISION}..."
  "${MPI_RUN}" "${mpi_extra_args[@]}" -n "${nproc}" ./benchmark_F_IO_mpi "${np_per_rank}" "${NREPEAT}" "${NVAR}" \
    | tee "run_np${nproc}.log"
  grep '^RESULT_CSV,' "run_np${nproc}.log" | sed 's/^RESULT_CSV,//' >> benchmark_results.csv
done

python3 plot_benchmark.py benchmark_results.csv
echo "Wrote benchmark_results.csv, benchmark_io_speedup.png, and benchmark_io_speed.png"
