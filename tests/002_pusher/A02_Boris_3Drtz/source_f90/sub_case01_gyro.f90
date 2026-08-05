subroutine sub_case01_gyro(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

    implicit none

    integer, intent(in) :: nstep
    real,    intent(in) :: dt,qm,B0,Ex,v0
    real,    intent(in) :: v_init(1:3),E0(1:3)
    character(len=*), intent(in) :: fname

    ! Cylindrical Boris uses (r, theta, z) for position and (vr, vphi, vz)
    ! for velocity. Initial Cartesian state is shifted to (x0, 0, 0) with a
    ! purely azimuthal initial velocity v_init_cart = (0, v0, 0) so the
    ! gyro-orbit stays away from r = 0 (center is at (x0 + v0/omega, 0),
    ! min r = x0).

    integer :: istep,unit
    real :: k,omega,t,x0
    real :: x(1:3),v(1:3),E(1:3),B(1:3)
    real :: cos_t,sin_t
    real :: x_sim,y_sim,z_sim,vx_sim,vy_sim,vz_sim
    real :: vx_ana,vy_ana,vz_ana,x_ana,y_ana,z_ana
    real :: err_v,err_r,err_v_max,err_r_max,v2

    k     = 0.5*qm*dt
    omega = qm*B0
    x0    = 1.0

    ! At theta = 0, cylindrical components equal Cartesian components.
    x = (/x0, 0.0, 0.0/)
    v = (/0.0, v0,  0.0/)
    E = 0.0
    B = (/0.0, 0.0, B0/)

    err_v_max = 0.0
    err_r_max = 0.0

    open(newunit=unit,file=fname,status='replace',action='write')
    write(unit,'(a)') '# step t x y z vx vy vz v2 x_ana y_ana z_ana vx_ana vy_ana vz_ana err_v err_r'

    do istep = 0, nstep

        t = istep*dt

        ! Analytical Cartesian trajectory: circle of radius v0/omega about
        ! center (x0 + v0/omega, 0).
        vx_ana =  v0*sin(omega*t)
        vy_ana =  v0*cos(omega*t)
        vz_ana = 0.0

        if (abs(omega) > 0.0) then
            x_ana = x0 + (v0/omega)*(1.0 - cos(omega*t))
            y_ana =       (v0/omega)*sin(omega*t)
        else
            x_ana = x0
            y_ana = v0*t
        end if
        z_ana = 0.0

        ! Convert simulated cylindrical state to Cartesian for comparison.
        cos_t = cos(x(2))
        sin_t = sin(x(2))
        x_sim  = x(1)*cos_t
        y_sim  = x(1)*sin_t
        z_sim  = x(3)
        vx_sim = v(1)*cos_t - v(2)*sin_t
        vy_sim = v(1)*sin_t + v(2)*cos_t
        vz_sim = v(3)

        v2    = vx_sim**2 + vy_sim**2 + vz_sim**2
        err_v = sqrt((vx_sim-vx_ana)**2 + (vy_sim-vy_ana)**2 + (vz_sim-vz_ana)**2)
        err_r = sqrt((x_sim - x_ana )**2 + (y_sim - y_ana )**2 + (z_sim - z_ana )**2)
        err_v_max = max(err_v_max, err_v)
        err_r_max = max(err_r_max, err_r)

        write(unit,'(i8,1x,16(es16.8,1x))') istep,t, x_sim,y_sim,z_sim, vx_sim,vy_sim,vz_sim, v2, &
                                           x_ana,y_ana,z_ana, vx_ana,vy_ana,vz_ana, err_v,err_r

        if (istep < nstep) then
            call sub_A02_Boris_3Drtz_push_v_x(x,v,E,B,k,dt)
        end if

    end do

    close(unit)
    write(*,'("Case ",a6,": max|v-v_ana| = ",es12.4,"   max|r-r_ana| = ",es12.4)') 'gyro', err_v_max, err_r_max

end subroutine sub_case01_gyro
