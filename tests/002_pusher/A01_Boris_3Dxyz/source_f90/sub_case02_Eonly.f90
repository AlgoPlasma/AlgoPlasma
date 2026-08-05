subroutine sub_case02_Eonly(nstep,dt,qm,B0,Ex,v0,v_init,E0,fname)

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

	k      = 0.5*qm*dt

	v      = v_init
	r      = 0.0
	E      = E0
	B      = 0.0

	err_v_max = 0.0
	err_r_max = 0.0

	open(newunit=unit,file=fname,status='replace',action='write')
	write(unit,'(a)') '# step t x y z vx vy vz v2 x_ana y_ana z_ana vx_ana vy_ana vz_ana err_v err_r'

	do istep = 0, nstep

		t = istep*dt

		vx_ana = v_init(1) + qm*E(1)*t
		vy_ana = v_init(2) + qm*E(2)*t
		vz_ana = v_init(3) + qm*E(3)*t

		x_ana = v_init(1)*t + 0.5*qm*E(1)*t*t
		y_ana = v_init(2)*t + 0.5*qm*E(2)*t*t
		z_ana = v_init(3)*t + 0.5*qm*E(3)*t*t

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
	write(*,'("Case ",a6,": max|v-v_ana| = ",es12.4,"   max|r-r_ana| = ",es12.4)') 'Eonly', err_v_max, err_r_max

end subroutine sub_case02_Eonly
