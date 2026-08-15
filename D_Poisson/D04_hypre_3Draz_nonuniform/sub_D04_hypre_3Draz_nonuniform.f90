!> @file sub_D04_hypre_3Draz_nonuniform.f90
!> @brief Solve the assembled 3D cylindrical nonuniform Poisson system
!> using the HYPRE Struct PFMG solver with a 7-point stencil.
!> @author Yinjian ZHAO (2026/03/30), adapted with staged flags (2026/04/01)
!>
!> @details
!> This subroutine is the HYPRE solver driver only: it does not assemble
!> geometry-dependent coefficients. The caller must provide an already
!> assembled 7-point matrix in `A_values` together with the matching
!> right-hand side `RHS` and initial guess / solution vector `phi1d`.
!>
!> This subroutine supports three phases controlled by flags:
!> - Initialization: create and assemble persistent HYPRE objects
!>   (`grid`, `stencil`, `A`, `b`, `x`).
!> - Optional matrix update: rebuild the matrix using coefficients from
!>   `A_values`.
!> - Solve: update vectors, run `HYPRE_StructPFMGSolve`, and return
!>   the solution in `phi1d`. `HYPRE_StructPFMGSetup` is called only
!>   when initializing or when matrix coefficients are updated.
!>
!> MPI usage:
!> - Each rank contributes one local structured box.
!> - `il` / `iu` are the lower / upper indices of that local box in
!>   global index space.
!> - `phi1d`, `RHS`, and `A_values` contain owned-cell values only for
!>   that local box; they do not include ghost cells.
!> - `periodic` contains the global periodic lengths expected by
!>   `HYPRE_StructGridSetPeriodic`.
!>
!> The 7 stencil entries are ordered as:
!> `0`: ( 0, 0, 0), `1`: (-1, 0, 0), `2`: ( 1, 0, 0),
!> `3`: ( 0,-1, 0), `4`: ( 0, 1, 0), `5`: ( 0, 0,-1),
!> `6`: ( 0, 0, 1).
!>
!> If `do_finalize` is true, the routine destroys persistent HYPRE objects
!> and returns immediately.
!
!> @param[in] fcomm: integer, MPI communicator (Fortran handle) used by HYPRE.
!> @param[in] il: integer (1:3), lower indices of this rank-local box in
!> global `r,alpha,z` cell-center index space.
!> @param[in] iu: integer (1:3), upper indices of this rank-local box in
!> global `r,alpha,z` cell-center index space.
!> @param[in,out] phi1d: real(:), owned-cell initial values on input and
!> owned-cell solution values on output for this local box.
!> @param[in] RHS: real(:), owned-cell assembled right-hand-side values on
!> `il:iu` for this local box.
!> @param[in] tolerance: real, solver convergence tolerance.
!> @param[in] A_values: real(:), owned-cell assembled matrix coefficients for
!> `il:iu`, with 7 stencil entries per cell.
!> @param[in] periodic: integer (1:3), global periodicity lengths in
!> `r,alpha,z` passed to `HYPRE_StructGridSetPeriodic`.
!> @param[in] do_init: logical, create/assemble persistent HYPRE objects.
!> @param[in] do_updateA: logical, update matrix coefficients from `A_values`.
!> @param[in] do_finalize: logical, destroy persistent HYPRE objects.
!> @param[in,out] solver: integer(8), persistent HYPRE `StructPFMG` handle.
!> @param[in,out] grid: integer(8), HYPRE `StructGrid` handle.
!> @param[in,out] stencil: integer(8), HYPRE `StructStencil` handle.
!> @param[in,out] A: integer(8), HYPRE `StructMatrix` handle.
!> @param[in,out] b: integer(8), HYPRE `StructVector` (RHS) handle.
!> @param[in,out] x: integer(8), HYPRE `StructVector` (solution) handle.

subroutine sub_D04_hypre_3Draz_nonuniform(fcomm,il,iu,phi1d, &
    RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
    solver,grid,stencil,A,b,x)

    use mpi
    implicit none
    include "HYPREf.h"

    integer :: fcomm
    integer,dimension(1:3) :: il,iu
    real,dimension(:) :: phi1d,RHS
    real :: tolerance
    real,dimension(:) :: A_values
    integer,dimension(1:3) :: periodic
    logical :: do_init,do_updateA,do_finalize
    integer(8) :: solver,grid,stencil,A,b,x

    integer :: ndim,nentries,ierr
    integer,dimension(7) :: stencil_indices
    integer,dimension(3) :: offsets
    logical :: need_setup

    if (do_finalize) then
        call HYPRE_StructPFMGDestroy(solver,ierr)
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
    need_setup = .false.

    if (do_init) then
        call HYPRE_StructGridCreate(fcomm,ndim,grid,ierr)
        call HYPRE_StructGridSetExtents(grid,il,iu,ierr)
        call HYPRE_StructGridSetPeriodic(grid,periodic,ierr)
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

        call HYPRE_StructPFMGCreate(fcomm,solver,ierr)
        call HYPRE_StructPFMGSetNonZeroGuess(solver,ierr)
        call HYPRE_StructPFMGSetPrintLevel(solver,0,ierr)
        call HYPRE_StructPFMGSetRelaxType(solver,2,ierr)
        call HYPRE_StructPFMGSetTol(solver,tolerance,ierr)

        need_setup = .true.
    end if

    if (do_updateA) then
        call HYPRE_StructMatrixDestroy(A,ierr)
        call HYPRE_StructMatrixCreate(fcomm,grid,stencil,A,ierr)
        call HYPRE_StructMatrixInitialize(A,ierr)
        call HYPRE_StructMatrixSetBoxValues(A,il,iu,nentries, &
            stencil_indices,A_values,ierr)
        call HYPRE_StructMatrixAssemble(A,ierr)
        need_setup = .true.
    end if

    call HYPRE_StructVectorSetBoxValues(b,il,iu,RHS,ierr)
    call HYPRE_StructVectorSetBoxValues(x,il,iu,phi1d,ierr)
    call HYPRE_StructVectorAssemble(b,ierr)
    call HYPRE_StructVectorAssemble(x,ierr)

    call HYPRE_StructPFMGSetTol(solver,tolerance,ierr)
    if (need_setup) then
        call HYPRE_StructPFMGSetup(solver,A,b,x,ierr)
    end if
    call HYPRE_StructPFMGSolve(solver,A,b,x,ierr)
    call HYPRE_StructVectorGetBoxValues(x,il,iu,phi1d,ierr)

end subroutine sub_D04_hypre_3Draz_nonuniform
