#include "../../../../A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz/mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90"
#include "mod_manageProcedures.f90"

program main

    use mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher
    use mod_manageProcedures
    implicit none

    integer :: nstep
    real    :: dt,qm,B0,Ex,v0
    real    :: v_init(1:3), E0(1:3)
    character(len=256) :: fname

    ! ---- Case 1: relativistic gyro (v0 = 0.9c, gamma ≈ 2.294) ----
    nstep  = 4000
    dt     = 1.0e-3
    qm     = 1.0
    B0     = 5.0
    Ex     = 0.0
    v0     = 299792458.0 * 0.9   ! 0.9c
    v_init = 0.0
    E0     = 0.0
    fname  = 'case01_gyro.dat'
    call sub_case01_gyro(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

    ! ---- Case 2: high-gamma ExB drift (gamma=20, force-free) ----
    ! Ex = -vy*B0 so the Lorentz force vanishes; x should remain 0.
    ! HC achieves this; Boris drifts by ~2321 under the same setup.
    nstep  = 10000
    dt     = 1.0e-2
    qm     = 1.0
    B0     = 1.0
    Ex     = -299792458.0 * sqrt(1.0 - 1.0/400.0)  ! = -vy for gamma=20
    v0     = 0.0
    v_init = 0.0
    E0     = 0.0
    fname  = 'case02_exb_drift.dat'
    call sub_case02_exb_drift(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

    ! ---- Case 3: WarpX reference test (positron qm=e/me, same CFL dt) ----
    ! dt=0.01 >> T_gyro by ~7 orders; HC still achieves |x| < 0.001
    nstep  = 10000
    dt     = 1.0e-2
    qm     = 1.602176634e-19 / 9.1093837015e-31   ! positron e/me ≈ 1.7588e11 C/kg
    B0     = 1.0
    Ex     = -299792458.0 * sqrt(1.0 - 1.0/400.0) ! gamma=20 force-free
    v0     = 0.0
    v_init = 0.0
    E0     = 0.0
    fname  = 'case03_warpx_exb_drift.dat'
    call sub_case03_warpx_exb_drift(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

end program main
