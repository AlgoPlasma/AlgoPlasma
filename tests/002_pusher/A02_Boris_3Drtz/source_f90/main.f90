#include "../../../../A_Pusher/A02_Boris_3Drtz/mod_A02_Boris_3Drtz.f90"
#include "mod_manageProcedures.f90"

program main

    use mod_A02_Boris_3Drtz
    use mod_manageProcedures
    implicit none

    integer :: nstep
    real    :: dt,qm,B0,Ex,v0
    real    :: v_init(1:3), E0(1:3)
    character(len=256) :: fname

    ! ---- Case 1: gyro ----
    nstep  = 2000
    dt     = 1.0e-3
    qm     = 1.0
    B0     = 5.0
    Ex     = 0.0
    v0     = 1.0e8
    v_init = 0.0
    E0     = 0.0
    fname  = 'case01_gyro.dat'
    call sub_case01_gyro(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

    ! ---- Case 2: E only ----
    nstep  = 2000
    dt     = 2.0e-3
    qm     = 1.0
    B0     = 0.0
    Ex     = 0.0
    v0     = 0.0
    v_init = (/0.0,0.0,0.0/)
    E0     = (/1.0,0.0,0.0/)
    fname  = 'case02_Eonly.dat'
    call sub_case02_Eonly(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

    ! ---- Case 3: ExB ----
    nstep  = 4000
    dt     = 1.0e-3
    qm     = 1.0
    B0     = 3.0
    Ex     = 1.2
    v0     = 0.0
    v_init = (/0.7,0.1,0.0/)
    E0     = 0.0
    fname  = 'case03_ExB.dat'
    call sub_case03_exb(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

    ! ---- Case 4: pure ExB drift ----
    nstep  = 4000
    dt     = 1.0e-3
    qm     = 1.0
    B0     = 3.0
    Ex     = 1.2
    v0     = 0.0
    v_init = 0.0
    E0     = 0.0
    fname  = 'case04_ExB_drift.dat'
    call sub_case04_exb_drift(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

end program main
