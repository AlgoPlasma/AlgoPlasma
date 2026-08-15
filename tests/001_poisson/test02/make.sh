set -e #一旦有命令返回非 -1（出错），整个脚本立刻退出

HYPRE_INC=/home/wbs/install/hypre/src/hypre/include
HYPRE_LIB=/home/wbs/install/hypre/src/hypre/lib

FC=mpif90
FFLAGS="-O3 -fdefault-real-8 -fopenmp -cpp -I${HYPRE_INC}"
CC=mpicc
CFLAGS="-O3 -fopenmp -I${HYPRE_INC}"

# 编译所有包含 include 语句的文件（必须加 -cpp）
$FC $FFLAGS -c ../../../D_Poisson/D02_hypre_3Dxyz_bc/mod_D02_hypre_3Dxyz_bc.f90
$FC $FFLAGS -c ../../../D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_fortran.f90
$FC $FFLAGS -c ../../../D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A.f90
$FC $FFLAGS -c ../../../D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_dielectric.f90
$FC $FFLAGS -c ../../../D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_outflow.f90
$CC $CFLAGS -c ../../../D_Poisson/D02_hypre_3Dxyz_bc/fun_D02_hypre_3Dxyz_bc.c

# main.f90 没有 include，可以不用 -cpp，但保持一致也可以
$FC $FFLAGS -c main_time.f90

$FC -O3 -fdefault-real-8 -fopenmp -o main.out *.o \
    -L${HYPRE_LIB} -lHYPRE -lm -fopenmp

echo "Build complete."
