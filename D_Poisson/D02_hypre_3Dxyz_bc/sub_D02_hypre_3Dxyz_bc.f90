!> @file sub_D02_hypre_3Dxyz_bc.f90
!> @brief
!> Fortran wrapper that calls the C/HYPRE solver fun_D02_hypre_3Dxyz_bc()
!> to solve the 3D Poisson equation on a cell-centered structured grid.
!> @author Yinjian ZHAO (2025/11/06)

!> This module-level routine sits between the purely Fortran side
!> (where the coefficient matrix @c A_values and right-hand side
!> @c rho1d are assembled by @c sub_D02_hypre_3Dxyz_bc_A) and the C
!> wrapper @c fun_D02_hypre_3Dxyz_bc() that drives the HYPRE Struct
!> interface and PFMG solver.

!> @param[in] ilower:
!>   (1:3), lower logical indices of the local cell-centered grid box
!>   on this MPI rank, in HYPRE's index space @f$(i_\text{L}, j_\text{L}, k_\text{L})@f$.
!> @param[in] iupper:
!>   (1:3), upper logical indices of the local cell-centered grid box
!>   on this MPI rank, in HYPRE's index space
!>   @f$(i_\text{U}, j_\text{U}, k_\text{U})@f$, inclusive.
!> @param[in,out] phi1d:
!>   1D array of length
!>   @f$(i_\text{U}-i_\text{L}+1)(j_\text{U}-j_\text{L}+1)
!>      (k_\text{U}-k_\text{L}+1)@f$ holding the potential:
!>   - on input: initial guess for the Poisson solve (e.g. zeros),
!>   - on output: converged potential @f$\phi@f$ returned by HYPRE.
!> @param[in] rho1d:
!>   1D array of the same length as @c phi1d, containing the right-hand
!>   side @f$h^2 \rho / \varepsilon_0@f$ (charge density plus boundary-condition contributions),
!>   as assembled by @c sub_D02_hypre_3Dxyz_bc_A.
!> @param[in] tolerance:
!>   Convergence tolerance passed to the HYPRE PFMG solver; the solve
!>   stops once the residual norm is below this threshold.
!> @param[in] A_values:
!>   Flattened 1D array of matrix coefficients for the 7-point stencil
!>   at all cells in the local box.  The length must be
!>   @f$(i_\text{U}-i_\text{L}+1)(j_\text{U}-j_\text{L}+1)
!>      (k_\text{U}-k_\text{L}+1)\times 7@f$, and the coefficient order
!>   for each cell must match the HYPRE stencil:
!>   center, xmin, xmax, ymin, ymax, zmin, zmax.
!> @param[in] period:
!>   (1:3), periodicity vector in grid units, as expected by
!>   @c HYPRE_StructGridSetPeriodic.  A zero component indicates
!>   non-periodic in that direction; a positive component sets the
!>   periodicity length.

!> @note
!> - This routine itself does not touch the contents of @c A_values or
!>   @c rho1d; it only forwards them to the C/HYPRE wrapper.
!> - All HYPRE-specific logic (grid, stencil, matrix, vectors, solver)
!>   is confined to @c fun_D02_hypre_3Dxyz_bc.c; this subroutine keeps
!>   the Fortran code independent of HYPRE's C API.
!> - The communicator used is @c MPI_COMM_WORLD. If a different
!>   communicator is desired, this subroutine can be extended to accept
!>   it as an additional argument.

subroutine sub_D02_hypre_3Dxyz_bc(&
    ilower,iupper,phi1d,rho1d,tolerance,A_values,period)

    use, intrinsic :: iso_c_binding
    use mpi
    use omp_lib

    implicit none

    ! C-interoperable interface to the HYPRE wrapper fun_D02_hypre_3Dxyz_bc().
    ! All kinds and shapes here must match the C function prototype.
    interface

        subroutine fun_D02_hypre_3Dxyz_bc(&
            comm,ilower,iupper,phi1d,rho1d,tolerance,&
            A_values,period) bind(c,name="fun_D02_hypre_3Dxyz_bc")

            use iso_c_binding

            ! Fortran integer handle for the MPI communicator,
            ! passed by reference to C and converted via MPI_Comm_f2c.
            integer(c_int)                :: comm

            ! Lower/upper logical indices of the local box (size-3 vectors).
            integer(c_int),dimension(1:3) :: ilower,iupper

            ! Potential and RHS arrays, passed as contiguous 1D double*.
            real(c_double)                :: phi1d(*),rho1d(*)

            ! Solver tolerance passed by value (C double).
            real(c_double),value          :: tolerance

            ! Flattened coefficient array A_values (7-point stencil).
            real(c_double)                :: A_values(*)

            ! Periodicity vector (size-3 integer).
            integer(c_int),dimension(1:3) :: period

        end subroutine

    end interface

    ! Local copies of arguments with explicit C-interoperable kinds.
    integer(c_int),dimension(1:3) :: ilower,iupper
    real(c_double),dimension(:)   :: phi1d,rho1d
    real(c_double)                :: tolerance
    real(c_double),dimension(:)   :: A_values
    integer(c_int),dimension(1:3) :: period

    ! Fortran-side MPI communicator handle (as integer),
    ! compatible with C int via c_int.
    integer(c_int) :: comm

    ! Use the global communicator MPI_COMM_WORLD. If needed, this can be
    ! generalized to accept user-provided communicators.
    comm = MPI_COMM_WORLD

    ! Delegate the actual Poisson solve to the C/HYPRE wrapper.
    ! On return, phi1d holds the converged potential on this rank.
    call fun_D02_hypre_3Dxyz_bc(&
        comm,ilower,iupper,phi1d,rho1d,tolerance,&
        A_values,period)

end subroutine sub_D02_hypre_3Dxyz_bc
