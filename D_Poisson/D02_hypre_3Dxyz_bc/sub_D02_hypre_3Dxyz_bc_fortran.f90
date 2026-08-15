!> @file sub_D02_hypre_3Dxyz_bc_fortran.f90
!> @brief Solve a 3D structured linear system using the HYPRE Struct PFMG solver
!>        with a 7-point finite-difference stencil (Fortran interface).
!> @author Baisheng WANG (2025/12/15), Yinjian ZHAO (2025/12/20).
!>
!> @details
!> This subroutine supports three phases controlled by flags:
!> - Initialization: create and assemble persistent HYPRE objects
!>   (``grid``, ``stencil``, ``A``, ``b``, ``x``).
!> - Optional matrix update: rebuild the matrix using coefficients from
!>   ``A_values`` (7-point stencil).
!> - Solve: update vectors, run ``HYPRE_StructPFMGSetup`` /
!>   ``HYPRE_StructPFMGSolve``, and return the solution in ``phi1d``.
!>
!> The 7 stencil entries are ordered as:
!> ``0``: ( 0, 0, 0), ``1``: (-1, 0, 0), ``2``: ( 1, 0, 0),
!> ``3``: ( 0,-1, 0), ``4``: ( 0, 1, 0), ``5``: ( 0, 0,-1),
!> ``6``: ( 0, 0, 1).
!>
!> If ``do_finalize`` is true, the routine destroys persistent HYPRE objects
!> and returns immediately.

!> @param[in] fcomm: integer, MPI communicator (Fortran handle) used by HYPRE
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z
!> @param[in,out] phi1d: real(:), initial values on input, solution on output
!> @param[in] rho1d: real(:), right-hand-side values on ``il:iu``
!> @param[in] tolerance: real, solver convergence tolerance
!> @param[in] A_values: real(:), matrix coefficients for ``il:iu`` (7 entries)
!> @param[in] period: integer (1:3), periodicity lengths for x,y,z
!> @param[in] do_init: logical, create/assemble persistent HYPRE objects
!> @param[in] do_updateA: logical, update matrix coefficients from ``A_values``
!> @param[in] do_finalize: logical, destroy persistent HYPRE objects
!> @param[in,out] grid: integer(8), HYPRE ``StructGrid`` handle
!> @param[in,out] stencil: integer(8), HYPRE ``StructStencil`` handle
!> @param[in,out] A: integer(8), HYPRE ``StructMatrix`` handle
!> @param[in,out] b: integer(8), HYPRE ``StructVector`` (RHS) handle
!> @param[in,out] x: integer(8), HYPRE ``StructVector`` (solution) handle

subroutine sub_D02_hypre_3Dxyz_bc_fortran(fcomm,il,iu,phi1d,rho1d, &
    tolerance,A_values,period,do_init,do_updateA,do_finalize, &
    grid,stencil,A,b,x)

    use mpi

    implicit none
    include "HYPREf.h"

    integer :: fcomm
    integer,dimension(1:3) :: il,iu
    real,dimension(:) :: phi1d,rho1d
    real :: tolerance
    real,dimension(:) :: A_values
    integer,dimension(1:3) :: period
    logical :: do_init,do_updateA,do_finalize
    integer(8) :: grid,stencil,A,b,x

    integer :: ndim,nentries,ierr
    integer,dimension(7) :: stencil_indices
    integer,dimension(3) :: offsets
    integer(8) :: solver

    if (do_finalize) then
        call HYPRE_StructMatrixDestroy(A,ierr)
        call HYPRE_StructStencilDestroy(stencil,ierr)
        call HYPRE_StructGridDestroy(grid,ierr)
        call HYPRE_StructVectorDestroy(x,ierr)
        call HYPRE_StructVectorDestroy(b,ierr)
        return
    end if

    ndim = 3
    nentries = 7
    stencil_indices = (/0,1,2,3,4,5,6/)

    if (do_init) then
        call HYPRE_StructGridCreate(fcomm,ndim,grid,ierr)
        call HYPRE_StructGridSetExtents(grid,il,iu,ierr)
        call HYPRE_StructGridSetPeriodic(grid,period,ierr)
        call HYPRE_StructGridAssemble(grid,ierr)

        call HYPRE_StructStencilCreate(ndim,nentries,stencil,ierr)
        offsets = (/0,0,0/)
        call HYPRE_StructStencilSetElement(stencil,0,offsets,ierr)
        offsets = (/-1,0,0/)
        call HYPRE_StructStencilSetElement(stencil,1,offsets,ierr)
        offsets = (/1,0,0/)
        call HYPRE_StructStencilSetElement(stencil,2,offsets,ierr)
        offsets = (/0,-1,0/)
        call HYPRE_StructStencilSetElement(stencil,3,offsets,ierr)
        offsets = (/0,1,0/)
        call HYPRE_StructStencilSetElement(stencil,4,offsets,ierr)
        offsets = (/0,0,-1/)
        call HYPRE_StructStencilSetElement(stencil,5,offsets,ierr)
        offsets = (/0,0,1/)
        call HYPRE_StructStencilSetElement(stencil,6,offsets,ierr)

        call HYPRE_StructMatrixCreate(fcomm,grid,stencil,A,ierr)
        call HYPRE_StructMatrixInitialize(A,ierr)
        call HYPRE_StructMatrixSetBoxValues(A,il,iu,nentries, &
            stencil_indices,A_values,ierr)
        call HYPRE_StructMatrixAssemble(A,ierr)

        call HYPRE_StructVectorCreate(fcomm,grid,b,ierr)
        call HYPRE_StructVectorCreate(fcomm,grid,x,ierr)
        call HYPRE_StructVectorInitialize(b,ierr)
        call HYPRE_StructVectorInitialize(x,ierr)
    end if

    if (do_updateA) then
        call HYPRE_StructMatrixDestroy(A,ierr)
        call HYPRE_StructMatrixCreate(fcomm,grid,stencil,A,ierr)
        call HYPRE_StructMatrixInitialize(A,ierr)
        call HYPRE_StructMatrixSetBoxValues(A,il,iu,nentries, &
            stencil_indices,A_values,ierr)
        call HYPRE_StructMatrixAssemble(A,ierr)
    end if

    call HYPRE_StructVectorSetBoxValues(b,il,iu,rho1d,ierr)
    call HYPRE_StructVectorSetBoxValues(x,il,iu,phi1d,ierr)
    call HYPRE_StructVectorAssemble(b,ierr)
    call HYPRE_StructVectorAssemble(x,ierr)

    call HYPRE_StructPFMGCreate(fcomm,solver,ierr)
    call HYPRE_StructPFMGSetNonZeroGuess(solver,ierr)
    call HYPRE_StructPFMGSetPrintLevel(solver,0,ierr)
    call HYPRE_StructPFMGSetRelaxType(solver,2,ierr)
    call HYPRE_StructPFMGSetTol(solver,tolerance,ierr)

    call HYPRE_StructPFMGSetup(solver,A,b,x,ierr)
    call HYPRE_StructPFMGSolve(solver,A,b,x,ierr)
    call HYPRE_StructVectorGetBoxValues(x,il,iu,phi1d,ierr)

    call HYPRE_StructPFMGDestroy(solver,ierr)

end subroutine sub_D02_hypre_3Dxyz_bc_fortran
