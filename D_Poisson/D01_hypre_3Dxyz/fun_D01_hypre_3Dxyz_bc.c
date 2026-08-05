/**
 * @file fun_D01_hypre_3Dxyz_bc.c
 * @brief 
 *  Calls the HYPRE to solve AX = b, where A is the discretized Laplacian, 
 *  b is the source term, and X is the electric potential, and supports MPI parallelism, 
 *  with each process responsible for a local portion of the grid.
 * 
 * @author Yinjian ZHAO, Baisheng WANG (2025/11/09)
 */
/**
 * @note
 * The grid adopts cell-centered layout. 
 * Periodic boundary conditions in the azimuthal direction can be applied via the included file 'inc_hypre_periodic_bc.c'. 
 * 
 * @param[in]  *fComm      MPI communicator, set to mpi_comm_world for global parallel communication
 * @param[in]  n           size of 3D array (local grid nodes per MPI process)
 * @param[out] phi1d      electric potential array.
 * @param[in]  rho1d       charge density array
 * @param[in]  ilower      lower physical indices(3D array, of this mpi rank)
 * @param[in]  iupper      upper physical indices(3D array, of this mpi rank)
 * @param[in]  il0         lower physical indices(3D array, of global model)
 * @param[in]  iu0         upper physical indices(3D array, of global model)
 * @param[in]  tolerance   Convergence threshold (stops iteration when error is below this value)
 * @param[in]  bc          boundary condition flag in x,z small and big.
 *                         0: inner; 1: Dirichlet; 2: Neumann; y is set to be periodic.
 *
 */

#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Struct linear solvers header */
#include "HYPRE_struct_ls.h"

void fun_d01_hypre_3dxyz_bc(
int *fComm, int n, double phi1d[], double rho1d[],
int ilower[], int iupper[], int il0[], int iu0[],
double tolerance, int bc[])
{

    HYPRE_StructGrid     grid;
    HYPRE_StructStencil  stencil;
    HYPRE_StructMatrix   A;
    HYPRE_StructVector   b;
    HYPRE_StructVector   x;
    HYPRE_StructSolver   solver;

    /* Initialize MPI */
    MPI_Comm comm;
    comm = MPI_Comm_f2c ( *fComm );

    /* Initialize HYPRE */
    HYPRE_Initialize();

    /* Set grid. */
    {

        /* Set up a grid. Each processor describes the piece
        of the grid that it owns. */

        /* Create an empty 3D grid object. */
        HYPRE_StructGridCreate(MPI_COMM_WORLD, 3, &grid);

        /* Add boxes to the grid. */
        HYPRE_StructGridSetExtents(grid, ilower, iupper);

        /* Set periodic BC. */
        {
#           include "inc_hypre_periodic_bc.c"
        }

        /* This is a collective call finalizing the grid assembly.
        The grid is now ``ready to be used'' */
        HYPRE_StructGridAssemble(grid);

    }
//[set_matrix_stencil]
    /* Set stencil. */
    {
        /* Create an empty 3D, 7-pt stencil object */
        HYPRE_StructStencilCreate(3, 7, &stencil);
        /* Define the geometry of the stencil. Each represents a
           relative offset (in the index space). */
        {
            int entry;
            int offsets[7][3] = {{0,0,0},{-1,0,0},{1,0,0},{0,-1,0},{0,1,0},{0,0,-1},{0,0,1}};
            /* Assign each of the 7 stencil entries */
            for (entry = 0; entry < 7; entry++)
            {
               HYPRE_StructStencilSetElement(stencil, entry, offsets[entry]);
            }
        }
    }
//[set_matrix_stencil]

    /* Set up a Struct Matrix A. */
    {
        /* Create an empty matrix object */
        HYPRE_StructMatrixCreate(MPI_COMM_WORLD, grid, stencil, &A);

        /* Indicate that the matrix coefficients are ready to be set */
        HYPRE_StructMatrixInitialize(A);

        /* Set the matrix coefficients.  Each processor assigns coefficients
        for the boxes in the grid that it owns. Note that the coefficients
        associated with each stencil entry may vary from grid point to grid
        point if desired.  Here, we first set the same stencil entries for
        each grid point.  Then we make modifications to grid points near
        the boundary. */
//[set_matrix_values]
        int stencil_indices[7] = {0, 1, 2, 3, 4, 5, 6};
        int nentries = 7;
        int nvalues  = (iupper[0]-ilower[0]+1)*\
                       (iupper[1]-ilower[1]+1)*\
                       (iupper[2]-ilower[2]+1)*nentries;
        double *values = (double *) malloc(nvalues * sizeof(double));
        for (int i = 0; i < nvalues; i += nentries) {
            values[i] = 6.0;
            for (int j = 1; j < nentries; j++) {
                values[i + j] = -1.0;
            }
        }
//[set_matrix_values] 
        HYPRE_StructMatrixSetBoxValues(A, ilower, iupper, nentries,
                                       stencil_indices, values);
        free(values);

        // Set boundaries.
        {
#       include "inc_hypre_set_A_bc.c"
        }

        /* This is a collective call finalizing the matrix assembly.
           The matrix is now ``ready to be used'' */
        HYPRE_StructMatrixAssemble(A);
    }

    /* Set up Struct Vectors for b and x.  Each processor sets the vectors
       corresponding to its boxes. */
    {
        /* Create an empty vector object */
        HYPRE_StructVectorCreate(MPI_COMM_WORLD, grid, &b);
        HYPRE_StructVectorCreate(MPI_COMM_WORLD, grid, &x);

        /* Indicate that the vector coefficients are ready to be set */
        HYPRE_StructVectorInitialize(b);
        HYPRE_StructVectorInitialize(x);

        HYPRE_StructVectorSetBoxValues(b,ilower,iupper,rho1d);

        HYPRE_StructVectorSetBoxValues(x,ilower,iupper,phi1d);

        /* This is a collective call finalizing the vector assembly.
        The vectors are now ``ready to be used'' */
        HYPRE_StructVectorAssemble(b);
        HYPRE_StructVectorAssemble(x);
    }

    /* Set up and use a solver (See the Reference Manual for descriptions
       of all of the options.) */
    {

#       include "inc_hypre_solver.c"
       
        /* Get the local solution. */
        HYPRE_StructVectorGetBoxValues(x,ilower,iupper,phi1d);
    }

   /* Free memory */
   HYPRE_StructGridDestroy(grid);
   HYPRE_StructStencilDestroy(stencil);
   HYPRE_StructMatrixDestroy(A);
   HYPRE_StructVectorDestroy(b);
   HYPRE_StructVectorDestroy(x);

   /* Finalize Hypre */
   HYPRE_Finalize();

   return;

}
