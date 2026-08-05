set -e
mkdir -p build
cd build
gfortran -cpp -O3 -fdefault-real-8 ../source_f90/main.f90 -o main
