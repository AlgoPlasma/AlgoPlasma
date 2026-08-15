./clean.sh
mkdir -p build
cd build
# gfortran -O3 -fdefault-real-8 -fopenmp xxxx.f90
gfortran -cpp -O3 -fdefault-real-8 -fopenmp ../boris_xyz_SoA_omp.f90
