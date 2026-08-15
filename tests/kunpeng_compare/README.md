# Kunpeng Comparison Tests

This directory stores platform comparison cases for AlgoPlasma kernels. Each case
keeps the original benchmark program, raw logs from the compared machines, and
Python post-processing scripts.

Current case:

- `A01_Boris_3Dxyz_omp`: OpenMP performance comparison for the Boris pusher.
- `B01_Scatter_3Dxyz_omp`: OpenMP performance comparison for Cartesian scatter.
- `D01_hypre_3Dxyz_omp`: Poisson/HYPRE comparison for Kunpeng GCC, Kunpeng BiSheng, and AMD.
- `E_Maxwell`: AMD/Kunpeng comparison cases for Maxwell update kernels.
