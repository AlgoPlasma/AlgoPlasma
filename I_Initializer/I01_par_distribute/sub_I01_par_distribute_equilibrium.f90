!> @file   sub_I01_par_distribute_equilibrium.f90
!> @author Yinjian ZHAO (2025/11/03)
!> @brief  Particle initialization utilities.
!>         Exactly uniform in space and Maxwellian velocity (dx=dy=dz=1).
!> @details
!> This subroutine fills the particle array ``par`` with:
!> - **Spatial distribution**: exactly uniform in space inside each cell.
!> - **Velocity sampling**: Maxwellian (Gaussian) velocity with drift,
!>   sampled by the Box-Muller method.
!>
!> **Spatial distribution**
!> \snippet this exact_uniform
!> For each cell index \f$(i,j,k)\f$ and particle sub-index
!> \f$(i_p,j_p,k_p)\f$ with
!> \f[
!>   i_p=0,\dots,n_{\mathrm{ppc},x}-1,\quad
!>   j_p=0,\dots,n_{\mathrm{ppc},y}-1,\quad
!>   k_p=0,\dots,n_{\mathrm{ppc},z}-1,
!> \f]
!> particle positions are placed on an equidistant sub-grid inside each cell:
!> \f[
!>   x=(i-1)+\frac{i_p+1/2}{n_{\mathrm{ppc},x}},\quad
!>   y=(j-1)+\frac{j_p+1/2}{n_{\mathrm{ppc},y}},\quad
!>   z=(k-1)+\frac{k_p+1/2}{n_{\mathrm{ppc},z}}.
!> \f]
!> This assumes normalized mesh spacing \f$\Delta x=\Delta y=\Delta z=1\f$.
!>
!> **Velocity sampling (Box-Muller)**
!> \snippet this box_muller
!> Let \f$U_1,U_2,U_3,U_4\sim \mathrm{Uniform}(0,1)\f$ be independent.
!> Define:
!> \f[
!>   R_1=\sqrt{-2\ln U_1},\ \Theta_1=2\pi U_2,\quad
!>   R_2=\sqrt{-2\ln U_3},\ \Theta_2=2\pi U_4.
!> \f]
!> Then:
!> \f[
!>   Z_x=R_1\cos\Theta_1,\quad Z_y=R_1\sin\Theta_1,\quad
!>   Z_z=R_2\cos\Theta_2,
!> \f]
!> and for \f$\alpha\in\{x,y,z\}\f$:
!> \f[
!>   v_\alpha=v_{d,\alpha}+v_{t,\alpha}Z_\alpha,
!> \f]
!> where ``vt`` is the thermal speed and ``vd`` is the drift velocity.
!>
!> @note
!> - ``np`` is not passed; it must match ``il``, ``iu``, and ``nppc``.
!> - Default real precision is determined by compiler flags.
!> - ``random_number`` returns values in \f$[0,1)\f$; ``1-r`` is used to
!>   avoid \f$\ln(0)\f$, with an additional ``tiny`` guard for robustness.
!> - There are ``iu(1:3)-il(1:3)+1`` cells in each direction.
!>
!>
!> @param[out] par: real (1:6,1:np), particle array; 1-3 are ``x,y,z``,
!>                  4-6 are ``vx,vy,vz``; ``np`` is number of particles.
!> @param[in] nppc: integer (1:3), number of particles per cell in ``x,y,z``.
!> @param[in] il: integer (1:3), cell-center lower indices in ``x,y,z``.
!> @param[in] iu: integer (1:3), cell-center upper indices in ``x,y,z``.
!> @param[in] vt: real (1:3), thermal velocity in ``x,y,z``,
!>                \f$v_t=\sqrt{2kT/m}\f$.
!> @param[in] vd: real (1:3), drifting velocity in ``x,y,z``.

subroutine sub_I01_par_distribute_equilibrium(par,nppc,il,iu,vt,vd)

    implicit none

    real,dimension(:,:) :: par
    integer,dimension(1:3) :: nppc
    integer,dimension(1:3) :: il,iu
    real,dimension(1:3) :: vt,vd

    integer :: p,i,j,k,ip,jp,kp
    real,dimension(4) :: r
    real,dimension(3) :: inv_nppc
    real :: x0,y0,z0,u1,u2,the1,the2,g1,g2,g3
    real,parameter :: pi2 = 6.283185307179586

    inv_nppc(1) = 1.0/real(nppc(1))
    inv_nppc(2) = 1.0/real(nppc(2))
    inv_nppc(3) = 1.0/real(nppc(3))

    p = 1
    do k=il(3),iu(3)
    do j=il(2),iu(2)
    do i=il(1),iu(1)
        x0 = real(i-1)
        y0 = real(j-1)
        z0 = real(k-1)

        do kp=0,nppc(3)-1
        do jp=0,nppc(2)-1
        do ip=0,nppc(1)-1
            ! [exact_uniform]
            par(1,p) = x0 + (real(ip)+0.5)*inv_nppc(1)
            par(2,p) = y0 + (real(jp)+0.5)*inv_nppc(2)
            par(3,p) = z0 + (real(kp)+0.5)*inv_nppc(3)
            ! [exact_uniform]

            ! [box_muller]
            call random_number(r)

            u1 = sqrt(-2.0*log(max(tiny(1.0),1.0-r(1))))
            the1 = pi2*r(2)
            g1 = u1*cos(the1)
            g2 = u1*sin(the1)
            g3 = sqrt(-2.0*log(max(tiny(1.0),1.0-r(3)))) * cos(pi2*r(4))

            par(4,p) = vt(1)*g1 + vd(1)
            par(5,p) = vt(2)*g2 + vd(2)
            par(6,p) = vt(3)*g3 + vd(3)
            ! [box_muller]

            p = p + 1
        end do
        end do
        end do
    end do
    end do
    end do

end subroutine sub_I01_par_distribute_equilibrium
