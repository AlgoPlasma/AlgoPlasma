// The fixed potential values will be added to rho1d,
// and passed into this subroutine.

// k small
if (bc[2]==1)
{
    int il[3] = {ilower[0], ilower[1], ilower[2]};
    int iu[3] = {iupper[0], iupper[1], ilower[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 5;
    for (int i = 0; i < n; i++) { values[i] = 0.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 7.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

// k big
if (bc[3]==1)
{
    int il[3] = {ilower[0], ilower[1], iupper[2]};
    int iu[3] = {iupper[0], iupper[1], iupper[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 6;
    for (int i = 0; i < n; i++) { values[i] = 0.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 7.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

// i small
if (bc[0]==1)
{
    int il[3] = {ilower[0], ilower[1], ilower[2]};
    int iu[3] = {ilower[0], iupper[1], iupper[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 1;
    for (int i = 0; i < n; i++) { values[i] = 0.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 7.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

// i big
if (bc[1]==1)
{
    int il[3] = {iupper[0], ilower[1], ilower[2]};
    int iu[3] = {iupper[0], iupper[1], iupper[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 2;
    for (int i = 0; i < n; i++) { values[i] = 0.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 7.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

// i small
if (bc[0]==2)
{
    int il[3] = {ilower[0], ilower[1], ilower[2]};
    int iu[3] = {ilower[0], iupper[1], iupper[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 1;
    for (int i = 0; i < n; i++) { values[i] = 0.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 5.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

// i big
if (bc[1]==2)
{
    int il[3] = {iupper[0], ilower[1], ilower[2]};
    int iu[3] = {iupper[0], iupper[1], iupper[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 2;
    for (int i = 0; i < n; i++) { values[i] = 0.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 5.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

// set corners

if (bc[0]==1 && bc[2]==1)
{
    int il[3] = {ilower[0], ilower[1], ilower[2]};
    int iu[3] = {ilower[0], iupper[1], ilower[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 8.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

if (bc[1]==1 && bc[2]==1)
{
    int il[3] = {iupper[0], ilower[1], ilower[2]};
    int iu[3] = {iupper[0], iupper[1], ilower[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 8.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

if (bc[0]==1 && bc[3]==1)
{
    int il[3] = {ilower[0], ilower[1], iupper[2]};
    int iu[3] = {ilower[0], iupper[1], iupper[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 8.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

if (bc[1]==1 && bc[3]==1)
{
    int il[3] = {iupper[0], ilower[1], iupper[2]};
    int iu[3] = {iupper[0], iupper[1], iupper[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 8.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

if (bc[0]==2 && bc[2]==1)
{
    int il[3] = {ilower[0], ilower[1], ilower[2]};
    int iu[3] = {ilower[0], iupper[1], ilower[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 6.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}

if (bc[1]==2 && bc[2]==1)
{
    int il[3] = {iupper[0], ilower[1], ilower[2]};
    int iu[3] = {iupper[0], iupper[1], ilower[2]};
    int n = (iu[0]-il[0]+1)*(iu[1]-il[1]+1)*(iu[2]-il[2]+1);
    double *values = (double *) malloc( n * sizeof(double));
    int stencil_indices[1];
    stencil_indices[0] = 0;
    for (int i = 0; i < n; i++) { values[i] = 6.0; }
    HYPRE_StructMatrixSetBoxValues(A,il,iu,1,stencil_indices,values);
    free(values);
}
