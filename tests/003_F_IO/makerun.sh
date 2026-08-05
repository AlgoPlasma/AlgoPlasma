set -e

H5FLAGS="-cpp -DUSE_HDF5=1"

h5pfc ${H5FLAGS} -J . -c ../../F_IO/F01_par_load/mod_F01_par_load.f90
h5pfc ${H5FLAGS} -J . -c ../../F_IO/F02_par_output/mod_F02_par_output.f90
h5pfc ${H5FLAGS} -J . -c ../../F_IO/F03_field_load/mod_F03_field_load.f90
h5pfc ${H5FLAGS} -J . -c ../../F_IO/F04_field_output/mod_F04_field_output.f90
h5pfc ${H5FLAGS} -J . -I . -c test_F_IO.f90

h5pfc *.o -o test_F_IO

mpirun -n 4 ./test_F_IO
