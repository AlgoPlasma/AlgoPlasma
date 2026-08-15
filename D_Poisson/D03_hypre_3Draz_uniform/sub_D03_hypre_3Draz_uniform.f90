!> @file sub_D03_hypre_3Draz_uniform.f90
!> @brief Solve the assembled system for the single-domain
!> 3D cylindrical uniform-grid Poisson solver using HYPRE Struct PFMG.
!> @details
!> This routine is the HYPRE solver driver only: it does not assemble
!> geometry-dependent coefficients. The caller must provide an already
!> assembled 7-point matrix in `A_values` together with the matching
!> right-hand side `RHS` and the initial guess / solution vector `phi1d`.
!>
!> The stencil entries are ordered as:
!> - `0`: `( 0, 0, 0)`
!> - `1`: `(-1, 0, 0)`
!> - `2`: `( 1, 0, 0)`
!> - `3`: `( 0,-1, 0)`
!> - `4`: `( 0, 1, 0)`
!> - `5`: `( 0, 0,-1)`
!> - `6`: `( 0, 0, 1)`
!>
!> The routine supports three solver-control modes:
!> - initialization through `do_init`,
!> - matrix rebuild/update through `do_updateA`,
!> - final destruction of HYPRE objects through `do_finalize`.
!>
!> When `do_init` is true, the routine creates and assembles the HYPRE
!> structured grid, stencil, matrix, vectors, and PFMG solver object.
!> The matrix is initialized from `A_values`, and solver setup is marked
!> as required.
!>
!> When `do_updateA` is true, the routine destroys and rebuilds the HYPRE
!> structured matrix from the new `A_values`, while reusing the existing
!> grid, stencil, vectors, and solver object. Solver setup is then marked
!> as required again.
!>
!> When `do_finalize` is true, the routine destroys the solver, matrix,
!> stencil, grid, and vectors, then returns immediately.
!>
!> On every non-finalize call, the routine loads `RHS` into the HYPRE
!> vector `b`, loads the current `phi1d` into the HYPRE vector `x` as the
!> initial guess, assembles both vectors, performs solver setup if needed,
!> solves the linear system, and writes the solution back into `phi1d`.
!>
!> Periodic topology is passed directly to the HYPRE structured grid
!> through `HYPRE_StructGridSetPeriodic`.
!>
!> The PFMG solver is configured to use:
!> - nonzero initial guess,
!> - print level 0,
!> - relax type 2,
!> - user-supplied tolerance `tolerance`.
!> @author Baisheng WANG(2026/04/27)
!
!> @param[in] fcomm: integer, Fortran MPI communicator passed to HYPRE.
!> @param[in] il: integer (1:3), lower cell-center indices in
!> `r,alpha,z`.
!> @param[in] iu: integer (1:3), upper cell-center indices in
!> `r,alpha,z`.
!> @param[in,out] phi1d: real (:), flattened solution array. On input it
!> provides the initial guess; on output it is overwritten by the solved
!> potential.
!> @param[in] RHS: real (:), flattened right-hand-side array.
!> @param[in] tolerance: real scalar, convergence tolerance passed to the
!> HYPRE Struct PFMG solver.
!> @param[in] A_values: real (:), flattened 7-point stencil coefficients
!> used to assemble the HYPRE structured matrix.
!> @param[in] periodic: integer (1:3), periodic lengths in `r,alpha,z`
!> passed to `HYPRE_StructGridSetPeriodic`.
!> @param[in] do_init: logical, whether to create and initialize the HYPRE
!> grid, stencil, matrix, vectors, and solver.
!> @param[in] do_updateA: logical, whether to rebuild the HYPRE matrix from
!> the current `A_values`.
!> @param[in] do_finalize: logical, whether to destroy all HYPRE objects
!> and return immediately.
!> @param[in,out] solver: integer(8), HYPRE Struct PFMG solver handle.
!> @param[in,out] grid: integer(8), HYPRE structured grid handle.
!> @param[in,out] stencil: integer(8), HYPRE structured stencil handle.
!> @param[in,out] A: integer(8), HYPRE structured matrix handle.
!> @param[in,out] b: integer(8), HYPRE structured RHS vector handle.
!> @param[in,out] x: integer(8), HYPRE structured solution vector handle.
subroutine sub_D03_hypre_3Draz_uniform(fcomm,il,iu,phi1d, &
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
        ! Create and assemble the structured grid.
        call HYPRE_StructGridCreate(fcomm,ndim,grid,ierr)
        call HYPRE_StructGridSetExtents(grid,il,iu,ierr)
        call HYPRE_StructGridSetPeriodic(grid,periodic,ierr)
        call HYPRE_StructGridAssemble(grid,ierr)

        ! Create the 7-point structured stencil.
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

        ! Create and assemble the structured matrix from A_values.
        call HYPRE_StructMatrixCreate(fcomm,grid,stencil,A,ierr)
        call HYPRE_StructMatrixInitialize(A,ierr)
        call HYPRE_StructMatrixSetBoxValues(A,il,iu,nentries, &
            stencil_indices,A_values,ierr)
        call HYPRE_StructMatrixAssemble(A,ierr)

        ! Create and initialize the RHS and solution vectors.
        call HYPRE_StructVectorCreate(fcomm,grid,b,ierr)
        call HYPRE_StructVectorCreate(fcomm,grid,x,ierr)
        call HYPRE_StructVectorInitialize(b,ierr)
        call HYPRE_StructVectorInitialize(x,ierr)

        ! Create and configure the PFMG solver.
        call HYPRE_StructPFMGCreate(fcomm,solver,ierr)
        call HYPRE_StructPFMGSetNonZeroGuess(solver,ierr)
        call HYPRE_StructPFMGSetPrintLevel(solver,0,ierr)
        call HYPRE_StructPFMGSetRelaxType(solver,2,ierr)
        call HYPRE_StructPFMGSetTol(solver,tolerance,ierr)

        need_setup = .true.
    end if

    if (do_updateA) then
        ! Rebuild the structured matrix from the updated A_values.
        call HYPRE_StructMatrixDestroy(A,ierr)
        call HYPRE_StructMatrixCreate(fcomm,grid,stencil,A,ierr)
        call HYPRE_StructMatrixInitialize(A,ierr)
        call HYPRE_StructMatrixSetBoxValues(A,il,iu,nentries, &
            stencil_indices,A_values,ierr)
        call HYPRE_StructMatrixAssemble(A,ierr)

        need_setup = .true.
    end if

    ! Load the current RHS and initial guess into HYPRE vectors.
    call HYPRE_StructVectorSetBoxValues(b,il,iu,RHS,ierr)
    call HYPRE_StructVectorSetBoxValues(x,il,iu,phi1d,ierr)
    call HYPRE_StructVectorAssemble(b,ierr)
    call HYPRE_StructVectorAssemble(x,ierr)

    ! Update the tolerance and perform setup if required.
    call HYPRE_StructPFMGSetTol(solver,tolerance,ierr)
    if (need_setup) then
        call HYPRE_StructPFMGSetup(solver,A,b,x,ierr)
    end if

    ! Solve the linear system and copy the solution back to phi1d.
    call HYPRE_StructPFMGSolve(solver,A,b,x,ierr)
    call HYPRE_StructVectorGetBoxValues(x,il,iu,phi1d,ierr)

end subroutine sub_D03_hypre_3Draz_uniform