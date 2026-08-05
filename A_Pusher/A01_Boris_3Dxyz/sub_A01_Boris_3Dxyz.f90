!> @file sub_A01_Boris_3Dxyz.f90
!> @brief Performs a non-relativistic 3D Boris velocity update for a single
!>        particle: applies the electric-field half-kicks and magnetic-field
!>        rotation to advance @f$\mathbf{v}@f$ over one full time step.
!> @author Yinjian ZHAO, Zhongping ZHAO (2025/11/04).

!> @param[in,out] v
!>        real (1:3), particle velocity
!>        @f$\mathbf{v} = (v_x, v_y, v_z)@f$ at the beginning of the time step;
!>        on exit, velocity after one full non-relativistic Boris update.
!>
!> @param[in] E
!>        real (1:3), electric field
!>        @f$\mathbf{E} = (E_x, E_y, E_z)@f$ at the particle position.
!>
!> @param[in] B
!>        real (1:3), magnetic field
!>        @f$\mathbf{B} = (B_x, B_y, B_z)@f$ at the particle position.
!>
!> @param[in] k
!>        real, equal to @f$q \Delta t/2m@f$, where @f$q@f$ and
!>        @f$m@f$ are the particle charge and mass, and @f$\Delta t@f$ is
!>        the time-step size. It controls the strength of the electric kicks
!>        and the rotation in the magnetic field.

subroutine sub_A01_Boris_3Dxyz(v,E,B,k)

    implicit none

    real,dimension(1:3) :: v,E,B
    real :: k

    real :: Bm,t,s
    real,dimension(1:3) :: v_neg,vp,v_pos

    Bm = sqrt(B(1)**2+B(2)**2+B(3)**2)
    if (Bm<tiny(1.0_4)) then
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

end subroutine sub_A01_Boris_3Dxyz

! Reviewed by Yinjian ZHAO
