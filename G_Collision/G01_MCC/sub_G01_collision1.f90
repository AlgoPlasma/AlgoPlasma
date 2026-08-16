!> @file sub_G01_collision1.f90
!> @brief Electron-neutral collision process based on Vahedi's MCC algorithm.

!> @details
!> This subroutine implements a Monte Carlo collision (MCC) model for
!> electron-neutral interactions following the classic algorithm proposed
!> by V. Vahedi (CPC 87, 1995, 179-198). Elastic scattering, excitation, and
!> ionization processes are handled using the null-collision method.
!> The maximum collision frequency ``nu_max`` is computed only once and
!> reused in subsequent calls. Particle collisions are sampled statistically,
!> and ionization events generate new electron and ion particles while
!> accumulating the ionization source term ``S`` on the grid.

!> @author Lihuan XIE (2025/12/18)

!> @param[in,out] np1: integer, number of electron particles.
!> @param[in,out] np2: integer, number of ion particles.
!> @param[in] npmax1: integer, maximum number of electron particles.
!> @param[in] npmax2: integer, maximum number of ion particles.
!> @param[in,out] par1: real (1:6,1:npmax1), electron particle array.
!> @param[in,out] par2: real (1:6,1:npmax2), ion particle array.
!> @param[in] dt: real, simulation time step.
!> @param[in] e: real, unit charge.
!> @param[in] m1: real, electron mass.
!> @param[in] m2: real, neutral particle mass.
!> @param[in] Nmax: integer, maximum number of energy grid points.
!> @param[in] Ntype: integer, number of collision types.
!> @param[in] cross_section: real (1:2,1:Nmax,1:Ntype), cross-section tables.
!> @param[in] collision_type: integer (1:Ntype), collision type identifiers.
!> @param[in] vti: real, thermal velocity of ions.
!> @param[in] vd: real (1:3), drifting velocity.
!> @param[in] energy_excitation: real, excitation energy threshold.
!> @param[in] energy_ionization: real, ionization energy threshold.
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.
!> @param[in] den: real, neutral density defined on grid points.
!> @param[in,out] S: real, ionization source term on grid points.
!> @param[in] energy_min: real, minimum energy (eV) for nu_prime evaluation.
!> @param[in] energy_max: real, maximum energy (eV) for nu_prime evaluation.
!> @param[in] eV: real, electron volt conversion factor.
!> @param[in] wei: real, particle weight.
!> @param[in,out] nu_max: real, maximum collision frequency ``nu_prime``.

subroutine sub_G01_collision1(np1,np2,npmax1,npmax2,par1,par2,&
    dt,e,m1,m2,Nmax,Ntype,cross_section,collision_type,vti,vd,&
    energy_excitation,energy_ionization,il,iu,den,S,&
    energy_min,energy_max,eV,wei,nu_max)

    use mpi

    implicit none

    integer :: np1,np2,npmax1,npmax2
    real,dimension(1:6,1:npmax1) :: par1
    real,dimension(1:6,1:npmax2) :: par2
    real :: dt,e,m1,m2
    integer :: Nmax,Ntype
    real,dimension(1:2,1:Nmax,1:Ntype) :: cross_section
    integer :: collision_type(1:Ntype)
    real :: vti,vd(1:3)
    real :: energy_excitation,energy_ionization
    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-1:iu(1),il(2)-1:iu(2),il(3)-1:iu(3)) :: den,S
    real :: energy_min,energy_max
    real :: eV,wei
    real :: nu_max

    real :: P_null,R,v2,vm,energy,nn,fi,fj,fk
    integer :: Nc,i,j,ip,ii,jj,kk
    integer,dimension(:),allocatable :: flag
    real :: buf1,buf2,nu(0:Ntype)
    integer,parameter :: nnn = 5000
    real :: nu_sum(0:nnn),energy_range
    real :: nu_p
    integer :: ierr

    S = 0.0

    ! Compute nu_p and P_null based on Eq. (5) and Eq. (6) in V. Vahedi (CPC 87, 1995, 179-198).
    if (nu_max < 0.0) then
        nu_sum = 0.0
        do i = 0,nnn
            energy_range = energy_min + (energy_max - energy_min)/real(nnn)*i
            do j = 1,Ntype
                nu_sum(i) = nu_sum(i) + &
                    fun_G01_cross_section(energy_range,Nmax,cross_section(:,:,j))* &
                    sqrt(energy_range*e*2.0/(m1*m2/(m1 + m2)))
            end do
        end do
        nu_max = maxval(nu_sum)
    end if

    nu_p = nu_max*maxval(den)
    call mpi_allreduce(nu_p,buf1,1,mpi_double,mpi_max,mpi_comm_world,ierr)
    nu_p = buf1

    P_null = 1.0 - exp(-nu_p*dt)

    ! Get the number of collisions Nc.
    call random_number(R)
    if (P_null*np1 - real(floor(P_null*np1)) > R) then
        Nc = floor(P_null*np1) + 1
    else
        Nc = floor(P_null*np1)
    end if

    ! Used to indicate if a particle has collided.
    allocate(flag(1:np1))
    flag = 0

    ! Loop over Nc colliding particles.
    i = 1
    do
        if (i > Nc) exit

        call random_number(R)
        ip = floor(R*np1) + 1
        if (ip > size(flag)) cycle
        if (flag(ip) == 1) cycle
        flag(ip) = 1

        v2 = dot_product(par1(4:6,ip),par1(4:6,ip))
        energy = 0.5*m1*v2 / e
        vm = sqrt(v2)

        ! Do an interpolation to find the density of the particle position. 
        ! @_@ dx=dy=dz=1 is assumed!
        ii = floor(par1(1,ip))
        jj = floor(par1(2,ip))
        kk = floor(par1(3,ip))
        fi = par1(1,ip) - real(ii)
        fj = par1(2,ip) - real(jj)
        fk = par1(3,ip) - real(kk)

        nn = den(ii  ,jj  ,kk  )*(1.0 - fi)*(1.0 - fj)*(1.0 - fk) + &
             den(ii+1,jj  ,kk  )*(      fi)*(1.0 - fj)*(1.0 - fk) + &
             den(ii  ,jj+1,kk  )*(1.0 - fi)*(      fj)*(1.0 - fk) + &
             den(ii  ,jj  ,kk+1)*(1.0 - fi)*(1.0 - fj)*(      fk) + &
             den(ii+1,jj+1,kk  )*(      fi)*(      fj)*(1.0 - fk) + &
             den(ii+1,jj  ,kk+1)*(      fi)*(1.0 - fj)*(      fk) + &
             den(ii  ,jj+1,kk+1)*(1.0 - fi)*(      fj)*(      fk) + &
             den(ii+1,jj+1,kk+1)*(      fi)*(      fj)*(      fk)

        ! Compute nu for each collision type.
        nu(0) = 0.0
        do j = 1,Ntype
            nu(j) = fun_G01_cross_section( &
                energy,Nmax,cross_section(1:2,1:Nmax,j))*vm*nn
        end do

        ! Handle different collision type. 
        call random_number(R)
        j = 1
        do
            if (j > Ntype) exit
            buf1 = sum(nu(0:j-1)) / nu_p
            buf2 = sum(nu(0:j))   / nu_p

            if (R > buf1 .and. R <= buf2) then

                ! Do e-n elastic scattering.
                if (collision_type(j) == 1) then
                    call sub_G01_electron(par1(4:6,ip),m1,m2,e,&
                        -1.0,-1.0,&
                        par1(1:3,ip),par1(1:6,np1+1),par2(1:6,np2+1),&
                        vti,vd(1:3),eV)
                    exit

                ! Do excitation.
                else if (collision_type(j) == 2 .and. energy > energy_excitation) then
                    call sub_G01_electron(par1(4:6,ip),m1,m2,e,&
                        energy_excitation,-1.0,&
                        par1(1:3,ip),par1(1:6,np1+1),par2(1:6,np2+1),&
                        vti,vd(1:3),eV)
                    exit

                ! Do ionization.
                else if (collision_type(j) == 3 .and. energy > energy_ionization) then
                    call sub_G01_electron(par1(4:6,ip),m1,m2,e,&
                        -1.0,energy_ionization,&
                        par1(1:3,ip),par1(1:6,np1+1),par2(1:6,np2+1),&
                        vti,vd(1:3),eV)

                    np1 = np1 + 1
                    np2 = np2 + 1
                    S(ii  ,jj  ,kk  ) = S(ii  ,jj  ,kk  ) + (1.0 - fi)*(1.0 - fj)*(1.0 - fk)
                    S(ii+1,jj  ,kk  ) = S(ii+1,jj  ,kk  ) + (      fi)*(1.0 - fj)*(1.0 - fk)
                    S(ii  ,jj+1,kk  ) = S(ii  ,jj+1,kk  ) + (1.0 - fi)*(      fj)*(1.0 - fk)
                    S(ii  ,jj  ,kk+1) = S(ii  ,jj  ,kk+1) + (1.0 - fi)*(1.0 - fj)*(      fk)
                    S(ii+1,jj+1,kk  ) = S(ii+1,jj+1,kk  ) + (      fi)*(      fj)*(1.0 - fk)
                    S(ii+1,jj  ,kk+1) = S(ii+1,jj  ,kk+1) + (      fi)*(1.0 - fj)*(      fk)
                    S(ii  ,jj+1,kk+1) = S(ii  ,jj+1,kk+1) + (1.0 - fi)*(      fj)*(      fk)
                    S(ii+1,jj+1,kk+1) = S(ii+1,jj+1,kk+1) + (      fi)*(      fj)*(      fk)
                    exit
                end if

            end if
            j = j + 1
        end do

        i = i + 1
    end do

    S = S * wei

    deallocate(flag)

end subroutine sub_G01_collision1
