! Replicates the WarpX HC pusher reference test:
!   Examples/Tests/particle_pusher/inputs_test_3d_particle_pusher
! A positron (qm = e/me ≈ 1.7588e11 C/kg) in a gamma=20 force-free ExB field.
! dt ≈ 0.01 s matches the WarpX CFL for an 8x8x8 grid over [-2.077e7, 2.077e7]^3.
! Each dt spans ~14 million gyrations, yet HC keeps x ≈ 0.
! WarpX reference errors after 10000 steps:
!   Boris: ~2321   Vay: ~0.00011   HC: ~0.00011   tolerance: 0.001
subroutine sub_case03_warpx_exb_drift(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

    implicit none

    integer, intent(in) :: nstep
    real,    intent(in) :: dt,qm,B0,Ex,v0
    real,    intent(in) :: v_init(1:3),E0(1:3)
    character(len=*), intent(in) :: fname

    integer :: istep,unit
    real :: k,t
    real :: v(1:3),E(1:3),B(1:3)
    real :: r(1:3)
    real :: vx_ana,vy_ana,vz_ana,x_ana,y_ana,z_ana
    real :: err_v,err_r,err_v_max,err_r_max,v2
    real :: vdrift

    k = 0.5*qm*dt

    E = (/Ex,0.0,0.0/)
    B = (/0.0,0.0,B0/)

    vdrift = -Ex/B0
    v      = (/0.0, vdrift, 0.0/)
    r      = 0.0

    err_v_max = 0.0
    err_r_max = 0.0

    open(newunit=unit,file=fname,status='replace',action='write')
    write(unit,'(a)') '# step t x y z vx vy vz v2 x_ana y_ana z_ana vx_ana vy_ana vz_ana err_v err_r'

    do istep = 0, nstep

        t = istep*dt

        vx_ana = 0.0
        vy_ana = vdrift
        vz_ana = 0.0

        x_ana  = 0.0
        y_ana  = vdrift*t
        z_ana  = 0.0

        v2    = v(1)**2 + v(2)**2 + v(3)**2
        err_v = sqrt((v(1)-vx_ana)**2 + (v(2)-vy_ana)**2 + (v(3)-vz_ana)**2)
        err_r = sqrt((r(1)-x_ana)**2 + (r(2)-y_ana)**2 + (r(3)-z_ana)**2)
        err_v_max = max(err_v_max, err_v)
        err_r_max = max(err_r_max, err_r)

        write(unit,'(i8,1x,16(es16.8,1x))') istep,t, r(1),r(2),r(3), v(1),v(2),v(3), v2, &
                                           x_ana,y_ana,z_ana, vx_ana,vy_ana,vz_ana, err_v,err_r

        if (istep < nstep) then
            call sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v,E,B,k)
            r = r + v*dt
        end if

    end do

    close(unit)
    write(*,'("Case ",a6,": max|v-v_ana| = ",es12.4,"   max|r-r_ana| = ",es12.4)') 'WarpX ', err_v_max, err_r_max
    write(*,'("         final |x|         = ",es12.4)') abs(r(1))
    if (abs(r(1)) < 0.001) then
        write(*,'("         WarpX tol 0.001   PASS  (ref HC ~1.1e-4, Boris ~2321)")')
    else
        write(*,'("         WarpX tol 0.001   FAIL")')
    end if

end subroutine sub_case03_warpx_exb_drift
