!> @file sub_A02_Boris_3Drtz_push_v_x.f90
!> @brief Perform a non-relativistic Boris push for a single particle in
!>        cylindrical coordinates. Given the electric and magnetic fields at
!>        the particle position, this subroutine advances both the position
!>        @f$\mathbf{x} = (r,\theta,z)@f$ and the velocity
!>        @f$\mathbf{v} = (v_r, v_\theta, v_z)@f$ over one full time step
!>        using the cylindrical Boris scheme.
!> @author Zhongping ZHAO (2025/11/20)

!> @param[in,out] x
!>        real (1:3), particle position in cylindrical coordinates, 
!>        @f$\mathbf{x} = (r,\theta,z)@f$ is 
!>        the particle position at the beginning of the time step; on exit,
!>        @f$\mathbf{x}@f$ contains the updated position after one full Boris
!>        update.
!>
!> @param[in,out] v
!>        real (1:3), particle velocity in cylindrical coordinates, 
!>        @f$\mathbf{v} = (v_r, v_\theta, v_z)@f$
!>        is the particle velocity at the beginning of the time step; on exit,
!>        @f$\mathbf{v}@f$ contains the updated velocity after one full 
!>        Boris update.
!>
!> @param[in] E
!>        real (1:3), electric field @f$\mathbf{E} = (E_r, E_\theta, E_z)@f$ evaluated at the particle position in cylindrical components.
!>
!> @param[in] B
!>        real (1:3), magnetic field @f$\mathbf{B} = (B_r, B_\theta, B_z)@f$ evaluated at the particle position in cylindrical components.
!>
!> @param[in] k
!>        real, Boris parameter @f$k = q \Delta t/2 m@f$ combining the
!>        particle charge-to-mass ratio and half of the time-step size.
!>
!> @param[in] dt
!>        real, time-step size @f$\Delta t@f$ used for advancing the particle
!>        position in the cylindrical geometry step.

subroutine sub_A02_Boris_3Drtz_push_v_x(x,v,E,B,k,dt)

    implicit none

    real,dimension(1:3) :: x,v,E,B
    real :: k,dt

    real :: Bm,t,s
    real,dimension(1:3) :: v_neg,vp,v_pos
    real :: phi,psi,sina,cosa
    real :: vr_star,vt_star

    Bm = sqrt(B(1)**2+B(2)**2+B(3)**2)
    if (abs(Bm)<tiny(1.0_4)) then
        v = v + E*k*2.0
    else
        v_neg = v + E*k
        t = tan(k*Bm)/Bm
        vp(1) = v_neg(1) + t*(v_neg(2)*B(3)-v_neg(3)*B(2))
        vp(2) = v_neg(2) + t*(v_neg(3)*B(1)-v_neg(1)*B(3))
        vp(3) = v_neg(3) + t*(v_neg(1)*B(2)-v_neg(2)*B(1))
        s = 2.0*t/(1.0+t*t*Bm*Bm)
        v_pos(1) = v_neg(1) + s*(vp(2)*B(3)-vp(3)*B(2))
        v_pos(2) = v_neg(2) + s*(vp(3)*B(1)-vp(1)*B(3))
        v_pos(3) = v_neg(3) + s*(vp(1)*B(2)-vp(2)*B(1))
        v = v_pos + E*k
    end if

    phi = x(1) + v(1)*dt
    psi = v(2)*dt
    x(1) = sqrt(phi**2+psi**2)
    if (abs(x(1))<tiny(1.0_4)) then
        sina = 0.0
        cosa = 1.0
    else
        sina = psi / x(1)
        cosa = phi / x(1)
        x(2) = x(2) + atan2(psi, phi)
    end if
    x(3) = x(3) + v(3)*dt
    vr_star = v(1)
    vt_star = v(2)
    v(1) = cosa*vr_star + sina*vt_star
    v(2) = -sina*vr_star + cosa*vt_star

end subroutine sub_A02_Boris_3Drtz_push_v_x
