!> @file    sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90
!> @author  Zilong PENG (2025/12/03)
!> @brief   Relativistic Higuera–Cary 3D velocity pusher.
!> @details
!> This routine advances a particle velocity ``v`` under electric field ``E`` and magnetic field ``B`` 
!> using the relativistic Higuera–Cary algorithm. The proper velocity (i.e., momentum per unit rest mass;
!> the spatial part of the four-velocity) ``u = γv`` is updated by a half electric kick, 
!> an exact algebraic magnetic rotation, and a second half electric kick. The updated ``u`` is converted back to ``v``. 
!> The updated momentum is converted back to velocity. This scheme improves numerical stability and 
!> accuracy over the Boris relativistic pusher.


!> @param[in,out] v
!>        real array (1:3), on entry, particle velocity
!>        @f$\mathbf{v} = (v_x, v_y, v_z)@f$ at the beginning of the time step;
!>        on exit, velocity after one full relativistic Higuera-Cary update.
!>
!> @param[in] E
!>        real array (1:3), electric field
!>        @f$\mathbf{E} = (E_x, E_y, E_z)@f$ at the particle position.
!>
!> @param[in] B
!>        real array (1:3), magnetic field
!>        @f$\mathbf{B} = (B_x, B_y, B_z)@f$ at the particle position.
!>
!> @param[in] k
!>        scalar factor equal to @f$q \Delta t/2m@f$, where @f$q@f$ and
!>        @f$m@f$ are the particle charge and mass and @f$\Delta t@f$ is the
!>        time-step size. It controls the strength of the electric kicks and
!>        the rotation in the magnetic field.

subroutine sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v,E,B,k)

    implicit none

    real :: v(3),E(3),B(3),k
    real :: beta(3),t(3),u_minus(3),u_plus(3),u_old(3),u_new(3)
    real :: beta2,sigma,u_satr,u_t
    real :: Bm,s
    real :: gamma_old,gamma_plus,gamma_new,gamma_minus
    real :: invclight,invclightsq
    real,parameter :: c = 299792458.0

    invclight = 1.0/c
    invclightsq = 1.0/(c*c)

    Bm = sqrt(B(1)**2+B(2)**2+B(3)**2)

    gamma_old = 1.0/sqrt(1.0 - (v(1)**2+v(2)**2+v(3)**2)*invclightsq)

    u_old(1) = gamma_old*v(1)
    u_old(2) = gamma_old*v(2)
    u_old(3) = gamma_old*v(3)

    u_minus(1) = u_old(1) + E(1)*k
    u_minus(2) = u_old(2) + E(2)*k
    u_minus(3) = u_old(3) + E(3)*k
    gamma_minus=1.0 + (u_minus(1)*u_minus(1) + u_minus(2)*u_minus(2) + u_minus(3)*u_minus(3))*invclightsq

    beta(1) = k*B(1)
    beta(2) = k*B(2)
    beta(3) = k*B(3)
    beta2 = beta(1)**2+beta(2)**2+beta(3)**2

    sigma = gamma_minus - beta2
    u_satr = (u_minus(1)*beta(1) + u_minus(2)*beta(2) + u_minus(3)*beta(3))*invclight
    gamma_plus = sqrt(0.5*(sigma + sqrt(sigma*sigma + 4.0*(beta2 + u_satr*u_satr))))

    t(1) = beta(1)/gamma_plus
    t(2) = beta(2)/gamma_plus
    t(3) = beta(3)/gamma_plus

    s = 1.0/(1.0 + (t(1)*t(1) + t(2)*t(2) + t(3)*t(3)))

    u_t = u_minus(1)*t(1) + u_minus(2)*t(2) + u_minus(3)*t(3)

    u_plus(1) = s*(u_minus(1) + u_minus(2)*t(3) - u_minus(3)*t(2) + u_t*t(1))
    u_plus(2) = s*(u_minus(2) + u_minus(3)*t(1) - u_minus(1)*t(3) + u_t*t(2))
    u_plus(3) = s*(u_minus(3) + u_minus(1)*t(2) - u_minus(2)*t(1) + u_t*t(3))

    u_new(1) = u_plus(1) + k*E(1) + u_plus(2)*t(3) - u_plus(3)*t(2)
    u_new(2) = u_plus(2) + k*E(2) + u_plus(3)*t(1) - u_plus(1)*t(3)
    u_new(3) = u_plus(3) + k*E(3) + u_plus(1)*t(2) - u_plus(2)*t(1)

    gamma_new = sqrt(1.0 + (u_new(1)**2 + u_new(2)**2 + u_new(3)**2)*invclightsq)

    v(1) = u_new(1)/gamma_new
    v(2) = u_new(2)/gamma_new
    v(3) = u_new(3)/gamma_new

end 
