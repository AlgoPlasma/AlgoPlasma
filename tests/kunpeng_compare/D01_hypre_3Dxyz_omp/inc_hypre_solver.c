HYPRE_StructPFMGCreate(comm, &solver);
HYPRE_StructPFMGSetTol(solver, tolerance);
HYPRE_StructPFMGSetPrintLevel(solver, 0);
HYPRE_StructPFMGSetRelaxType(solver, 2);
HYPRE_StructPFMGSetup(solver, A, b, x);
HYPRE_StructPFMGSolve(solver, A, b, x);
HYPRE_StructPFMGDestroy(solver);
