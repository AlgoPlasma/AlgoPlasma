!> @file sub_D01_hypre_3Dxyz_interface.f90
!> @brief   An interface between Fortran and C language to complete data transmission 
!> @author  Yinjian ZHAO, Baisheng WANG (2025/12/15)

!> @note        MPI communicator is set internally to ``mpi_comm_world``.
!> @param[in]   n           size of 1D array (local grid nodes per MPI process)
!> @param[out]  phi1d       electric potential array
!> @param[in]   rho1d       charge density
!> @param[in]   ilower      lower physical indices (3D array, of this MPI rank)
!> @param[in]   iupper      upper physical indices (3D array, of this MPI rank) 
!> @param[in]   il0         lower physical indices (3D array, of global model)
!> @param[in]   iu0         upper physical indices (3D array, of global model)
!> @param[in]   tolerance   Convergence threshold (stops iteration when error is below this value)
!> @param[in]   bc          Boundary condition flag on the lower/upper x and z faces. 0: inner; 1: Dirichlet; 2: Neumann; y is periodic.

!> @note
!> hypre is based on C language, this subroutine acts as a bridge between Fortran code and a C-implemented HYPRE solver, enabling parallel solution of linear systems.

subroutine sub_D01_hypre_3Dxyz_interface(&
    n,phi1d,rho1d,ilower,iupper,il0,iu0,tolerance,bc)

    use,intrinsic :: iso_c_binding
    use mpi
    use omp_lib

    implicit none

    interface

        subroutine fun_D01_hypre_3Dxyz_bc(&
            comm,n,phi1d,rho1d,ilower,iupper,il0,iu0,tolerance,bc) bind(c)

            use iso_c_binding

            !c parameters 
            integer(c_int) :: comm
            integer(c_int),value :: n
            real(c_double),dimension(1:n) :: phi1d,rho1d
            integer(c_int),dimension(1:3) :: ilower,iupper
            integer(c_int),dimension(1:3) :: il0,iu0
            real(c_double),value :: tolerance
            integer(c_int),dimension(1:4) :: bc

        end subroutine

    end interface

    ! fortran parameters
    integer :: n
    real,dimension(1:n) :: phi1d,rho1d
    integer,dimension(1:3) :: ilower,iupper
    integer,dimension(1:3) :: il0,iu0
    real :: tolerance
    integer,dimension(1:4) :: bc
    integer(c_int) :: comm

    comm = mpi_comm_world

    ! Call the HYPRE program in fun_D01_hypre_3Dxyz_bc.c to solve the 3D Poisson equation.
    call fun_D01_hypre_3Dxyz_bc(comm,n,phi1d,rho1d,ilower,iupper,il0,iu0,tolerance,bc)

end subroutine
