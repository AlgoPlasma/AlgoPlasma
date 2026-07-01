subroutine sub_case01_gyro(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

    implicit none

	integer, intent(in) :: nstep
	real,    intent(in) :: dt,qm,B0,Ex,v0
	real,    intent(in) :: v_init(1:3),E0(1:3)
	character(len=*), intent(in) :: fname

	integer :: istep,unit
	real :: k,omega,t
	real :: v(1:3),E(1:3),B(1:3)
	real :: r(1:3)
	real :: vx_ana,vy_ana,vz_ana,x_ana,y_ana,z_ana
	real :: err_v,err_r,err_v_max,err_r_max,v2

	k     = 0.5*qm*dt
	omega = qm*B0

	v  = (/v0,0.0,0.0/)
	r  = 0.0
	E  = 0.0
	B  = (/0.0,0.0,B0/)

	err_v_max = 0.0
	err_r_max = 0.0

	open(newunit=unit,file=fname,status='replace',action='write')
	write(unit,'(a)') '# step t x y z vx vy vz v2 x_ana y_ana z_ana vx_ana vy_ana vz_ana err_v err_r'

	do istep = 0, nstep

		t = istep*dt

		vx_ana = v0*cos(omega*t)
		vy_ana = -v0*sin(omega*t)
		vz_ana = 0.0

		if (abs(omega) > 0.0) then
			x_ana = (v0/omega)*sin(omega*t)
			y_ana = (v0/omega)*(cos(omega*t)-1.0)
		else
			x_ana = v0*t
			y_ana = 0.0
		end if
		z_ana = 0.0

		v2    = v(1)**2 + v(2)**2 + v(3)**2
		err_v = sqrt((v(1)-vx_ana)**2 + (v(2)-vy_ana)**2 + (v(3)-vz_ana)**2)
		err_r = sqrt((r(1)-x_ana)**2 + (r(2)-y_ana)**2 + (r(3)-z_ana)**2)
		err_v_max = max(err_v_max, err_v)
		err_r_max = max(err_r_max, err_r)

		write(unit,'(i8,1x,16(es16.8,1x))') istep,t, r(1),r(2),r(3), v(1),v(2),v(3), v2, &
										   x_ana,y_ana,z_ana, vx_ana,vy_ana,vz_ana, err_v,err_r

		if (istep < nstep) then
			call sub_A01_Boris_3Dxyz(v,E,B,k)
			r = r + v*dt
		end if

	end do

	close(unit)
	write(*,'("Case ",a6,": max|v-v_ana| = ",es12.4,"   max|r-r_ana| = ",es12.4)') 'gyro', err_v_max, err_r_max

end subroutine sub_case01_gyro
