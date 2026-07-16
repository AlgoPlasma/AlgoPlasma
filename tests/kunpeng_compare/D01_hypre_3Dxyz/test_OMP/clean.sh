#!/bin/bash
set -e

rm -f *.o *.mod main.out main_gcc.out main_bisheng.out
rm -f phi.dat run_gcc_np*_omp*_*.log run_bisheng_np*_omp*_*.log run_AMD_np*_omp*_*.log
rm -f time_3compares_np*.png time_compare_gcc_bisheng_np*.png
