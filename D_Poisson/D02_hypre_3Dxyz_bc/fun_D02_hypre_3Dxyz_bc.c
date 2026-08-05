/**
 * @file   fun_D02_hypre_3Dxyz_bc.c
 * @brief  C wrapper around HYPRE's structured interface to solve the
 *         3D Poisson equation with boundary conditions.
 * @author Yinjian ZHAO (2025/11/06)
 */

/**
 * @param[in]  fComm
 *   Pointer to a Fortran @c MPI_Comm (Fortran integer handle).
 *   It is converted internally to a C @c MPI_Comm via
 *   @c MPI_Comm_f2c.
 *
 * @param[in]  ilower
 *   Integer array of size 3. Logical lower indices
 *   (ilower[0], ilower[1], ilower[2]) of the structured grid box
 *   owned by this MPI rank, in HYPRE's index space.
 *
 * @param[in]  iupper
 *   Integer array of size 3. Logical upper indices
 *   (iupper[0], iupper[1], iupper[2]) of the structured grid box
 *   owned by this MPI rank, inclusive. Together with @p ilower they
 *   define a rectangular box of local cells.
 *
 * @param[in,out] phi1d
 *   1D array holding the potential @f$\phi@f$ at cell centers on this
 *   MPI process.
 *   - On input: initial guess for the iterative solver (may be zero
 *     or a more informed guess).
 *   - On output: converged solution after applying PFMG.
 *
 * @param[in]  rho1d
 *   1D array holding the right-hand side @f$h^2 \rho / \varepsilon_0 @f$ for each local
 *   cell center, including contributions from Dirichlet and Neumann
 *   boundary conditions as assembled in
 *   @c sub_D02_hypre_3Dxyz_bc_A.
 *
 * @param[in]  tolerance
 *   Convergence tolerance for the PFMG solver. The solve stops once
 *   the residual norm is below this value.
 *
 * @param[in]  A_values
 *   Flattened 1D array of matrix coefficients for the 7-point
 *   stencil at all local cells. Its layout must match the
 *   HYPRE stencil element order:
 *   - entry 0: center @f$(i,j,k)@f$,
 *   - entry 1: @f$(i-1,j,k)@f$ (xmin),
 *   - entry 2: @f$(i+1,j,k)@f$ (xmax),
 *   - entry 3: @f$(i,j-1,k)@f$ (ymin),
 *   - entry 4: @f$(i,j+1,k)@f$ (ymax),
 *   - entry 5: @f$(i,j,k-1)@f$ (zmin),
 *   - entry 6: @f$(i,j,k+1)@f$ (zmax).
 *
 * @param[in]  period
 *   Periodicity vector for the structured grid as expected by
 *   @c HYPRE_StructGridSetPeriodic. If non-zero components are
 *   provided, they specify the periodicity length (in grid units) in
 *   each coordinate direction. If all components are zero, the grid
 *   is treated as non-periodic.
 *
 * @note
 * - This function initializes and finalizes HYPRE internally
 *   (@c HYPRE_Initialize / @c HYPRE_Finalize). If you call multiple
 *   HYPRE-based routines in the same program, you may want to manage
 *   HYPRE's initialization/finalization at a higher level instead.
 * - The actual discretization of the Poisson operator, including the
 *   treatment of Dirichlet and Neumann boundary conditions, is done
 *   in @c sub_D02_hypre_3Dxyz_bc_A; this routine only wraps the
 *   linear solve.
 */

#include <mpi.h>
/* Struct linear solvers header */
#include "HYPRE_struct_ls.h"

void fun_D02_hypre_3Dxyz_bc(
    int       *fComm,
    HYPRE_Int  ilower[3],
    HYPRE_Int  iupper[3],
    double     phi1d[],
    double     rho1d[],
    double     tolerance,
    double     A_values[],
    HYPRE_Int  period[3])
{
    HYPRE_StructGrid     grid;
    HYPRE_StructStencil  stencil;
    HYPRE_StructMatrix   A;
    HYPRE_StructVector   b;
    HYPRE_StructVector   x;
    HYPRE_StructSolver   solver;

    /*------------------------------------------------------------------
     * 0. Convert Fortran MPI communicator and initialize HYPRE
     *------------------------------------------------------------------*/

    /* Convert Fortran MPI_Comm (integer handle) to C MPI_Comm. */
    MPI_Comm comm = MPI_Comm_f2c(*fComm);

    /* Initialize HYPRE library. This must be called before any other
       HYPRE_* function. In a larger application you might want to move
       HYPRE_Initialize / HYPRE_Finalize outside to avoid repeated
       initialization. */
    HYPRE_Initialize();

    /*------------------------------------------------------------------
     * 1. Set up the 3D structured grid
     *
     *    - Each MPI process describes the rectangular box of cells
     *      that it owns via (ilower, iupper).
     *    - Grid is cell-centered in logical coordinates, consistent
     *      with sub_D02_hypre_3Dxyz_bc_A.
     *------------------------------------------------------------------*/
    {
        /* Create an empty 3D grid object attached to the communicator.
           HYPRE_StructGridCreate is collective over the communicator. */
        HYPRE_StructGridCreate(comm, 3, &grid);

        /* Register the local logical box owned by this rank.
           ilower[0..2] and iupper[0..2] are inclusive bounds in
           index space. Multiple boxes could be added, but here we
           assume a single box per rank. */
        HYPRE_StructGridSetExtents(grid, ilower, iupper);

        /* Set periodicity of the domain. If 'period' has non-zero
           components, HYPRE will treat the grid as periodic in the
           corresponding directions, wrapping indices modulo the given
           period length. For non-periodic boundaries, this should be
           (0,0,0). */
        HYPRE_StructGridSetPeriodic(grid, period);

        /* Finalize grid assembly. After HYPRE_StructGridAssemble the
           grid structure is frozen and can be used to create matrices
           and vectors. This is a collective call. */
        HYPRE_StructGridAssemble(grid);
    }

    /*------------------------------------------------------------------
     * 2. Define the 7-point stencil matching sub_D02_hypre_3Dxyz_bc_A
     *
     *    Offsets correspond to:
     *      0: ( 0,  0,  0) center
     *      1: (-1,  0,  0) xmin
     *      2: ( 1,  0,  0) xmax
     *      3: ( 0, -1,  0) ymin
     *      4: ( 0,  1,  0) ymax
     *      5: ( 0,  0, -1) zmin
     *      6: ( 0,  0,  1) zmax
     *------------------------------------------------------------------*/
    {
        /* Create an empty 3D stencil object with 7 entries. */
        HYPRE_StructStencilCreate(3, 7, &stencil);

        /* Define the relative offsets (in index space) for each
           stencil entry. The order must be consistent with both
           A_values[] and stencil_indices[] below. */
        {
            HYPRE_Int entry;
            HYPRE_Int offsets[7][3] = {
                { 0,  0,  0},  /* center (i,j,k)   */
                {-1,  0,  0},  /* (i-1,j,k) xmin  */
                { 1,  0,  0},  /* (i+1,j,k) xmax  */
                { 0, -1,  0},  /* (i,j-1,k) ymin  */
                { 0,  1,  0},  /* (i,j+1,k) ymax  */
                { 0,  0, -1},  /* (i,j,k-1) zmin  */
                { 0,  0,  1}   /* (i,j,k+1) zmax  */
            };

            /* Register each stencil entry with HYPRE. The index 'entry'
               is later used as a stencil index when setting box values. */
            for (entry = 0; entry < 7; entry++)
            {
                HYPRE_StructStencilSetElement(stencil, entry, offsets[entry]);
            }
        }
    }

    /*------------------------------------------------------------------
     * 3. Set up the Struct matrix A
     *
     *    - Matrix is defined on the structured grid and stencil above.
     *    - Coefficients are provided in A_values[], already including
     *      the boundary-condition modifications done in Fortran.
     *------------------------------------------------------------------*/
    {
        /* Create an empty matrix object on the given grid and stencil.
           Collective over the communicator. */
        HYPRE_StructMatrixCreate(comm, grid, stencil, &A);

        /* Indicate that matrix entries will be set. */
        HYPRE_StructMatrixInitialize(A);

        /* Each process now sets the matrix coefficients for its local
           box (ilower..iupper). The array A_values contains, for each
           local cell, 7 consecutive stencil coefficients in the order
           given by stencil_indices. */
        {
            HYPRE_Int stencil_indices[7] = {0, 1, 2, 3, 4, 5, 6};
            HYPRE_Int nentries = 7;

            /* HYPRE_StructMatrixSetBoxValues assigns the coefficients
               for all cells in the local box in one call. The length
               of A_values must be:
                 (nx * ny * nz * nentries)
               where nx, ny, nz are the local box sizes. */
            HYPRE_StructMatrixSetBoxValues(A,
                                           ilower,
                                           iupper,
                                           nentries,
                                           stencil_indices,
                                           A_values);
        }

        /* Finalize matrix assembly. After this, A is ready for use in
           the solver. This is a collective call. */
        HYPRE_StructMatrixAssemble(A);
    }

    /*------------------------------------------------------------------
     * 4. Set up Struct vectors b (RHS) and x (solution)
     *
     *    - b is filled from rho1d.
     *    - x is initialized from phi1d (initial guess).
     *    - After the solve, x is copied back into phi1d.
     *------------------------------------------------------------------*/
    {
        /* Create empty vector objects on the grid. */
        HYPRE_StructVectorCreate(comm, grid, &b);
        HYPRE_StructVectorCreate(comm, grid, &x);

        /* Indicate that vector entries will be set. */
        HYPRE_StructVectorInitialize(b);
        HYPRE_StructVectorInitialize(x);

        /* Set the RHS values on the local box directly from rho1d.
           Length of rho1d must match the number of local cells. */
        HYPRE_StructVectorSetBoxValues(b, ilower, iupper, rho1d);

        /* Set the initial guess for x from phi1d. This can be zero
           (for a "cold start") or some previous solution. */
        HYPRE_StructVectorSetBoxValues(x, ilower, iupper, phi1d);

        /* Finalize vector assemblies. After this, b and x are ready
           for use in the solver. */
        HYPRE_StructVectorAssemble(b);
        HYPRE_StructVectorAssemble(x);
    }

    /*------------------------------------------------------------------
     * 5. Configure and run the PFMG solver
     *
     *    - PFMG is a geometric multigrid method optimized for
     *      structured grids.
     *    - We set tolerance, print level, and relaxation type.
     *------------------------------------------------------------------*/
    {
        /* Create an empty Struct PFMG solver object. */
        HYPRE_StructPFMGCreate(comm, &solver);

        /* Set convergence tolerance: iteration stops when residual is
           sufficiently small. */
        HYPRE_StructPFMGSetTol(solver, tolerance);

        /* Set amount of information printed:
           0 = no output, >0 prints residual history etc. */
        HYPRE_StructPFMGSetPrintLevel(solver, 0);

        /* Set relaxation type (smoother). The integer '2' selects one
           of the predefined relaxation schemes in HYPRE (e.g.
           red-black Gauss–Seidel, weighted Jacobi, etc.; see HYPRE
           manual for exact meaning). */
        HYPRE_StructPFMGSetRelaxType(solver, 2);

        /* Setup phase:
           builds internal multigrid hierarchy based on A, b, x. */
        HYPRE_StructPFMGSetup(solver, A, b, x);

        /* Solve phase:
           applies multigrid V-cycles until convergence (as defined by
           the tolerance above). On exit, vector x holds the solution. */
        HYPRE_StructPFMGSolve(solver, A, b, x);

        /* Destroy the solver object and free multigrid hierarchy. */
        HYPRE_StructPFMGDestroy(solver);

        /* Copy the local solution from HYPRE's vector x back into the
           caller-provided phi1d array. After this, phi1d contains the
           converged potential for all cells owned by this MPI rank. */
        HYPRE_StructVectorGetBoxValues(x, ilower, iupper, phi1d);
    }

    /*------------------------------------------------------------------
     * 6. Clean up HYPRE objects and finalize
     *------------------------------------------------------------------*/

    /* Destroy grid, stencil, matrix, and vectors to free all memory
       associated with them. */
    HYPRE_StructGridDestroy(grid);
    HYPRE_StructStencilDestroy(stencil);
    HYPRE_StructMatrixDestroy(A);
    HYPRE_StructVectorDestroy(b);
    HYPRE_StructVectorDestroy(x);

    /* Finalize HYPRE library. After this, no further HYPRE calls
       should be made unless HYPRE_Initialize is called again. */
    HYPRE_Finalize();

    return;
}
