$ErrorActionPreference = "Stop"

$CaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Resolve-Path (Join-Path $CaseDir "..\..")
$BuildDir = Join-Path $CaseDir "build"
$FigDir = Join-Path $CaseDir "fig"

$FC = if ($env:FC) { $env:FC } else { "mpif90" }
$Runner = if ($env:MPIEXEC) { $env:MPIEXEC } else { "mpiexec" }
$NP = if ($env:NP) { $env:NP } else { "4" }

$H01 = Join-Path $RootDir "H_MPI_Exchange\H01_mpi_exchange_field"
$H02 = Join-Path $RootDir "H_MPI_Exchange\H02_mpi_exchange_par"
$H03 = Join-Path $RootDir "H_MPI_Exchange\H03_mpi_exchange_den"

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $FigDir | Out-Null

$FFlags = @(
    "-cpp", "-O2", "-fdefault-real-8", "-ffree-line-length-none",
    "-J", $BuildDir,
    "-I", $H01, "-I", $H02, "-I", $H03
)

& $FC @FFlags -c (Join-Path $H01 "mod_H01_mpi_exchange_field.f90") `
    -o (Join-Path $BuildDir "mod_H01_mpi_exchange_field.o")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $FC @FFlags -c (Join-Path $H02 "mod_H02_mpi_exchange_par.f90") `
    -o (Join-Path $BuildDir "mod_H02_mpi_exchange_par.o")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $FC @FFlags -c (Join-Path $H03 "mod_H03_mpi_exchange_den.f90") `
    -o (Join-Path $BuildDir "mod_H03_mpi_exchange_den.o")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $FC @FFlags -c (Join-Path $CaseDir "test_H_MPI_Exchange.f90") `
    -o (Join-Path $BuildDir "test_H_MPI_Exchange.o")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $FC "-O2" "-fdefault-real-8" "-o" (Join-Path $BuildDir "test_H_MPI_Exchange.exe") `
    (Join-Path $BuildDir "mod_H01_mpi_exchange_field.o") `
    (Join-Path $BuildDir "mod_H02_mpi_exchange_par.o") `
    (Join-Path $BuildDir "mod_H03_mpi_exchange_den.o") `
    (Join-Path $BuildDir "test_H_MPI_Exchange.o")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Runner "-n" $NP (Join-Path $BuildDir "test_H_MPI_Exchange.exe")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Python = if ($env:PYTHON) { $env:PYTHON } else {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) { $cmd.Source } else { $null }
}

if ($Python) {
    & $Python (Join-Path $CaseDir "plot_mpi_exchange.py")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Warning "python not found; skip plotting."
}
