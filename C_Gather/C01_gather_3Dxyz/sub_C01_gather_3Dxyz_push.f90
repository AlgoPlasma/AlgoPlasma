!> @file sub_C01_gather_3Dxyz_push.f90
!> @author Yinjian ZHAO (2026/03/23).
!> @brief Gathers 3D xyz fields and advances a batch of particles.
!> @details
!>   This routine loops over all
!>   particles, gathers the trilinearly interpolated electric and magnetic
!>   fields, advances velocity with an inlined non-relativistic Boris update,
!>   and then advances position.
!>
!>   The optional ``dt`` defaults to ``1.0`` when omitted. This is useful for
!>   dimensionless runs where the normalized time step is one, and also allows
!>   callers to pass a larger effective step such as ion supercycling.
!>
!> @param[in] np
!>        integer, total number of particles in ``par``.
!> @param[in,out] par
!>        real (1:6,1:np), particle phase-space array.
!> @param[in] il
!>        integer (1:3), lower cell indices of the local subdomain.
!> @param[in] iu
!>        integer (1:3), upper cell indices of the local subdomain.
!> @param[in] Ex,Ey,Ez
!>        real 3D arrays, electric-field components on the local grid.
!> @param[in] Bx,By,Bz
!>        real 3D arrays, magnetic-field components on the local grid.
!> @param[in] q
!>        real, particle charge.
!> @param[in] m
!>        real, particle mass.
!> @param[in] dt
!>        optional real, time-step size. Defaults to ``1.0``.

subroutine sub_C01_gather_3Dxyz_push(np,par,il,iu,Ex,Ey,Ez,Bx,By,Bz,q,m,dt)

    implicit none

    integer :: np
    real,dimension(1:6,1:np) :: par
    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1) :: Ex,Ey,Ez
    real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1) :: Bx,By,Bz
    real :: q,m
    real,optional :: dt

    integer :: p,i,j,k
    real :: dt_use,kpush
    real :: x,y,z,fi,fj,fk
    real :: E(1:3),B(1:3)
    real :: Bm,t,s
    real :: v_neg(1:3),vp(1:3),v_pos(1:3)

    if (present(dt)) then
        dt_use = dt
    else
        dt_use = 1.0
    end if
    kpush = q/m*dt_use*0.5

    E = 0.0
    B = 0.0
    x = 0.0
    y = 0.0
    z = 0.0
    i = 0
    j = 0
    k = 0
    fi = 0.0
    fj = 0.0
    fk = 0.0
    Bm = 0.0
    t = 0.0
    s = 0.0
    v_neg = 0.0
    vp = 0.0
    v_pos = 0.0

    !$omp parallel default(firstprivate) shared(par,Ex,Ey,Ez,Bx,By,Bz,kpush,dt_use)
    !$omp do
    do p = 1,np

        x = par(1,p)+0.5
        y = par(2,p)+0.5
        z = par(3,p)+0.5
        i = floor(x)
        j = floor(y)
        k = floor(z)
        fi = x-real(i)
        fj = y-real(j)
        fk = z-real(k)

        E(1) = Ex(i  ,j  ,k  )*(1.0-fi)*(1.0-fj)*(1.0-fk) + &
               Ex(i+1,j  ,k  )*(    fi)*(1.0-fj)*(1.0-fk) + &
               Ex(i  ,j+1,k  )*(1.0-fi)*(    fj)*(1.0-fk) + &
               Ex(i  ,j  ,k+1)*(1.0-fi)*(1.0-fj)*(    fk) + &
               Ex(i+1,j+1,k  )*(    fi)*(    fj)*(1.0-fk) + &
               Ex(i+1,j  ,k+1)*(    fi)*(1.0-fj)*(    fk) + &
               Ex(i  ,j+1,k+1)*(1.0-fi)*(    fj)*(    fk) + &
               Ex(i+1,j+1,k+1)*(    fi)*(    fj)*(    fk)

        E(2) = Ey(i  ,j  ,k  )*(1.0-fi)*(1.0-fj)*(1.0-fk) + &
               Ey(i+1,j  ,k  )*(    fi)*(1.0-fj)*(1.0-fk) + &
               Ey(i  ,j+1,k  )*(1.0-fi)*(    fj)*(1.0-fk) + &
               Ey(i  ,j  ,k+1)*(1.0-fi)*(1.0-fj)*(    fk) + &
               Ey(i+1,j+1,k  )*(    fi)*(    fj)*(1.0-fk) + &
               Ey(i+1,j  ,k+1)*(    fi)*(1.0-fj)*(    fk) + &
               Ey(i  ,j+1,k+1)*(1.0-fi)*(    fj)*(    fk) + &
               Ey(i+1,j+1,k+1)*(    fi)*(    fj)*(    fk)

        E(3) = Ez(i  ,j  ,k  )*(1.0-fi)*(1.0-fj)*(1.0-fk) + &
               Ez(i+1,j  ,k  )*(    fi)*(1.0-fj)*(1.0-fk) + &
               Ez(i  ,j+1,k  )*(1.0-fi)*(    fj)*(1.0-fk) + &
               Ez(i  ,j  ,k+1)*(1.0-fi)*(1.0-fj)*(    fk) + &
               Ez(i+1,j+1,k  )*(    fi)*(    fj)*(1.0-fk) + &
               Ez(i+1,j  ,k+1)*(    fi)*(1.0-fj)*(    fk) + &
               Ez(i  ,j+1,k+1)*(1.0-fi)*(    fj)*(    fk) + &
               Ez(i+1,j+1,k+1)*(    fi)*(    fj)*(    fk)

        B(1) = Bx(i  ,j  ,k  )*(1.0-fi)*(1.0-fj)*(1.0-fk) + &
               Bx(i+1,j  ,k  )*(    fi)*(1.0-fj)*(1.0-fk) + &
               Bx(i  ,j+1,k  )*(1.0-fi)*(    fj)*(1.0-fk) + &
               Bx(i  ,j  ,k+1)*(1.0-fi)*(1.0-fj)*(    fk) + &
               Bx(i+1,j+1,k  )*(    fi)*(    fj)*(1.0-fk) + &
               Bx(i+1,j  ,k+1)*(    fi)*(1.0-fj)*(    fk) + &
               Bx(i  ,j+1,k+1)*(1.0-fi)*(    fj)*(    fk) + &
               Bx(i+1,j+1,k+1)*(    fi)*(    fj)*(    fk)

        B(2) = By(i  ,j  ,k  )*(1.0-fi)*(1.0-fj)*(1.0-fk) + &
               By(i+1,j  ,k  )*(    fi)*(1.0-fj)*(1.0-fk) + &
               By(i  ,j+1,k  )*(1.0-fi)*(    fj)*(1.0-fk) + &
               By(i  ,j  ,k+1)*(1.0-fi)*(1.0-fj)*(    fk) + &
               By(i+1,j+1,k  )*(    fi)*(    fj)*(1.0-fk) + &
               By(i+1,j  ,k+1)*(    fi)*(1.0-fj)*(    fk) + &
               By(i  ,j+1,k+1)*(1.0-fi)*(    fj)*(    fk) + &
               By(i+1,j+1,k+1)*(    fi)*(    fj)*(    fk)

        B(3) = Bz(i  ,j  ,k  )*(1.0-fi)*(1.0-fj)*(1.0-fk) + &
               Bz(i+1,j  ,k  )*(    fi)*(1.0-fj)*(1.0-fk) + &
               Bz(i  ,j+1,k  )*(1.0-fi)*(    fj)*(1.0-fk) + &
               Bz(i  ,j  ,k+1)*(1.0-fi)*(1.0-fj)*(    fk) + &
               Bz(i+1,j+1,k  )*(    fi)*(    fj)*(1.0-fk) + &
               Bz(i+1,j  ,k+1)*(    fi)*(1.0-fj)*(    fk) + &
               Bz(i  ,j+1,k+1)*(1.0-fi)*(    fj)*(    fk) + &
               Bz(i+1,j+1,k+1)*(    fi)*(    fj)*(    fk)

        Bm = sqrt(B(1)**2+B(2)**2+B(3)**2)
        if (Bm<tiny(1.0_4)) then
            par(4,p) = par(4,p) + E(1)*kpush*2.0
            par(5,p) = par(5,p) + E(2)*kpush*2.0
            par(6,p) = par(6,p) + E(3)*kpush*2.0
        else
            v_neg(1) = par(4,p) + E(1)*kpush
            v_neg(2) = par(5,p) + E(2)*kpush
            v_neg(3) = par(6,p) + E(3)*kpush
            t = tan(kpush*Bm)/Bm
            vp(1) = v_neg(1) + t*(v_neg(2)*B(3)-v_neg(3)*B(2))
            vp(2) = v_neg(2) + t*(v_neg(3)*B(1)-v_neg(1)*B(3))
            vp(3) = v_neg(3) + t*(v_neg(1)*B(2)-v_neg(2)*B(1))
            s = 2.0*t/(1.0+t*t*Bm*Bm)
            v_pos(1) = v_neg(1) + s*(vp(2)*B(3)-vp(3)*B(2))
            v_pos(2) = v_neg(2) + s*(vp(3)*B(1)-vp(1)*B(3))
            v_pos(3) = v_neg(3) + s*(vp(1)*B(2)-vp(2)*B(1))
            par(4,p) = v_pos(1) + E(1)*kpush
            par(5,p) = v_pos(2) + E(2)*kpush
            par(6,p) = v_pos(3) + E(3)*kpush
        end if

        par(1,p) = par(1,p) + par(4,p)*dt_use
        par(2,p) = par(2,p) + par(5,p)*dt_use
        par(3,p) = par(3,p) + par(6,p)*dt_use

    end do
    !$omp end do
    !$omp end parallel

end subroutine sub_C01_gather_3Dxyz_push
