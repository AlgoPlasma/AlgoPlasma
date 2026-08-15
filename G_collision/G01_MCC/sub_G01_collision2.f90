!> @file sub_G01_collision2.f90
!> @brief Ion-neutral collision process based on Vahedi's MCC algorithm.

!> @details
!> This subroutine implements a null-collision Monte Carlo algorithm
!> based on the classic work of V. Vahedi, CPC 87 (1995) 179-198.
!> It handles charge-exchange and ion-neutral collisions using
!> energy-dependent cross sections and spatially varying neutral density.

!> @author Lihuan XIE (2025/12/18)

!> @param[in,out] np: integer, number of ions.
!> @param[in] npmax: integer, maximum number of ions.
!> @param[in,out] par: real (1:6,1:npmax), particle array containing position and velocity.
!> @param[in] dt: real, time step.
!> @param[in] e: real, elementary charge.
!> @param[in] m: real, particle mass.
!> @param[in] Nmax: integer, maximum number of cross section data points.
!> @param[in] Ntype: integer, number of collision types.
!> @param[in] cross_section: real (1:2,1:Nmax,1:Ntype), cross section tables.
!> @param[in] collision_type: integer (1:Ntype), collision type identifiers.
!> @param[in] vti: real, thermal velocity.
!> @param[in] vd: real (1:3), drift velocity.
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.
!> @param[in] den: real (il(1)-1:iu(1),il(2)-1:iu(2),il(3)-1:iu(3)), neutral density.
!> @param[in] energy_min: real, minimum energy for collision frequency evaluation.
!> @param[in] energy_max: real, maximum energy for collision frequency evaluation.
!> @param[in,out] nu_max: real, maximum null-collision frequency ``nu_prime``.

subroutine sub_G01_collision2(np,npmax,par,dt,e,m,Nmax,Ntype,cross_section,&
    collision_type,vti,vd,il,iu,den,energy_min,energy_max,nu_max)

    use mpi

    implicit none

    integer :: np,npmax
    real :: par(1:6,1:npmax)
    real :: dt,e,m
    integer :: Nmax,Ntype
    real :: cross_section(1:2,1:Nmax,1:Ntype)
    integer :: collision_type(1:Ntype)
    real :: vti,vd(1:3)
    integer :: il(1:3),iu(1:3)
    real :: den(il(1)-1:iu(1),il(2)-1:iu(2),il(3)-1:iu(3))
    real :: energy_min,energy_max
    real :: nu_max

    integer,parameter :: nnn = 5000
    real :: nu_sum(0:nnn),energy_range
    integer :: i,j,ip,ii,jj,kk
    real :: nu_p,P_null,R,fi,fj,fk,nn
    integer :: Nc
    integer,allocatable :: flag(:)
    real :: v2,energy,vm
    real :: buf1,buf2,nu(0:Ntype)
    real :: rr(1:6),vn(1:3),vr(1:3)
    real,parameter :: pi2 = 6.283185307179586
    integer :: ierr
    real :: mu,phi,sint

    ! Compute nu_max and P_null in Eq.(5) and Eq.(6) based on the reference.
    if (nu_max < 0.0) then
        nu_sum = 0.0
        do i = 0,nnn
            energy_range = energy_min + (energy_max - energy_min) / real(nnn) * i
            do j = 1,Ntype
                nu_sum(i) = nu_sum(i) + &
                    fun_G01_cross_section(energy_range,Nmax,cross_section(:,:,j)) * &
                    sqrt(energy_range * e * 2.0 / (m * m / (m + m)))
            end do
        end do
        nu_max = maxval(nu_sum)
    end if

    nu_p = nu_max * maxval(den)
    call mpi_allreduce(nu_p,buf1,1,mpi_double,mpi_max,mpi_comm_world,ierr)
    nu_p = buf1

    P_null = 1.0 - exp(-nu_p * dt)

    ! Get the number of collisions Nc.
    call random_number(R)
    if (P_null * np - real(floor(P_null * np)) > R) then
        Nc = floor(P_null * np) + 1
    else
        Nc = floor(P_null * np)
    end if

    ! Used to indicate if a particle has collided.
    allocate(flag(1:np))
    flag = 0

    ! Loop over Nc colliding particles.
    i = 1
    do
        if (i > Nc) exit

        call random_number(R)
        ip = floor(R * np) + 1
        if (ip > size(flag)) cycle
        if (flag(ip) == 1) cycle
        flag(ip) = 1

        call random_number(rr(1:6))
        vn(1) = vti * sqrt(-2.0 * log(rr(1))) * cos(pi2 * rr(4)) + vd(1)
        vn(2) = vti * sqrt(-2.0 * log(rr(2))) * cos(pi2 * rr(5)) + vd(2)
        vn(3) = vti * sqrt(-2.0 * log(rr(3))) * cos(pi2 * rr(6)) + vd(3)

        vr(1:3) = par(4:6,ip) - vn(1:3)

        v2 = dot_product(vr,vr)
        energy = 0.5 * m * v2 / e / 2.0
        vm = sqrt(v2)

        ! Do an interpolation to find the density of the particle position.
        ii = floor(par(1,ip))
        jj = floor(par(2,ip))
        kk = floor(par(3,ip))
        fi = par(1,ip) - real(ii)
        fj = par(2,ip) - real(jj)
        fk = par(3,ip) - real(kk)
        nn = den(ii  ,jj  ,kk  )*(1.0-fi)*(1.0-fj)*(1.0-fk) + &
             den(ii+1,jj  ,kk  )*(    fi)*(1.0-fj)*(1.0-fk) + &
             den(ii  ,jj+1,kk  )*(1.0-fi)*(    fj)*(1.0-fk) + &
             den(ii  ,jj  ,kk+1)*(1.0-fi)*(1.0-fj)*(    fk) + &
             den(ii+1,jj+1,kk  )*(    fi)*(    fj)*(1.0-fk) + &
             den(ii+1,jj  ,kk+1)*(    fi)*(1.0-fj)*(    fk) + &
             den(ii  ,jj+1,kk+1)*(1.0-fi)*(    fj)*(    fk) + &
             den(ii+1,jj+1,kk+1)*(    fi)*(    fj)*(    fk)

        ! Compute nu for each collision type.
        nu(0) = 0.0
        do j = 1,Ntype
            nu(j) = fun_G01_cross_section(energy,Nmax,cross_section(:,:,j)) * vm * nn
        end do

        call random_number(R)
        j = 1
        do
            if (j > Ntype) exit
            buf1 = sum(nu(0:j-1)) / nu_p
            buf2 = sum(nu(0:j)) / nu_p
            if (R > buf1 .and. R <= buf2) then

                ! Do charge exchange.
                if (collision_type(j) == 1) then
                    par(4:6,ip) = vn(1:3)
                    exit

                ! Do ion-neutral.
                else if (collision_type(j) == 2) then
                    call random_number(rr(1:2))
                    mu = 2.0 * rr(1) - 1.0
                    phi = pi2 * rr(2)
                    sint = sqrt(1.0 - mu * mu)
                    rr(1) = sint * cos(phi)
                    rr(2) = sint * sin(phi)
                    rr(3) = mu
                    par(4:6,ip) = 0.5 * (par(4:6,ip) + vm * rr(1:3)) + vn(1:3)
                    exit
                end if

            end if
            j = j + 1
        end do

        i = i + 1
    end do

    deallocate(flag)

end subroutine sub_G01_collision2
