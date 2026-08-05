#include "../../../D_Poisson/D03_hypre_3Draz_uniform/mod_D03_hypre_3Draz_uniform.f90"
#include "../../../D_Poisson/D04_hypre_3Draz_nonuniform/mod_D04_hypre_3Draz_nonuniform.f90"

program main_compare_uniform_nonuniform_rz_mms

    use mpi
    use mod_D03_hypre_3Draz_uniform
    use mod_D04_hypre_3Draz_nonuniform
    implicit none
    include "HYPREf.h"

    integer,parameter :: BC_NONE       = 0
    integer,parameter :: BC_AXIS       = 1
    integer,parameter :: BC_DIRICHLET  = 2
    integer,parameter :: BC_NEUMANN    = 3

    integer,parameter :: ncase = 4
    real,parameter    :: pi = 3.14159265358979323846

    integer :: ierr,ierr_h
    integer :: mpi_i,mpi_n
    integer :: m

    integer :: nr_list(1:ncase), nz_list(1:ncase)
    real    :: err_inf_u(1:ncase), err_l2_u(1:ncase)
    real    :: err_inf_nu(1:ncase), err_l2_nu(1:ncase)

    real :: eps0,phi0
    real :: rmin,rmax,amin,amax,zmin,zmax
    real :: Lr,Lz
    real :: tolerance
    integer :: na
    real :: qr,qa,qz

    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
    call mpi_comm_size(mpi_comm_world,mpi_n,ierr)

    if (mpi_n /= 1) then
        if (mpi_i == 0) then
            write(*,*) 'ERROR: this test is intended for 1 MPI rank only.'
        end if
        call mpi_finalize(ierr)
        stop
    end if

    call HYPRE_Initialize(ierr_h)

    eps0 = 1.0
    phi0 = 1.0

    rmin = 0.0
    rmax = 2.0e-2
    amin = 0.0
    amax = 2.0*pi
    zmin = 0.0
    zmax = 4.0e-2

    Lr = rmax - rmin
    Lz = zmax - zmin

    na = 8
    tolerance = 1.0e-10

    ! nonuniform stretch ratios
    qr = 0.95
    qa = 1.00
    qz = 1.00

    nr_list = (/16, 24, 32, 48/)
    nz_list = (/16, 24, 32, 48/)

    if (mpi_i == 0) then
        write(*,*) '=========================================================='
        write(*,*) 'Uniform vs Nonuniform MMS comparison in rz quasi-2D'
        write(*,*) 'phi(r,z) = phi0 * [ (r/Lr)^2 - 0.5*(r/Lr)^4 ] * sin(pi*z/Lz)'
        write(*,*) 'r_lo = axis'
        write(*,*) 'r_hi = zero Neumann'
        write(*,*) 'z_lo = 0 V'
        write(*,*) 'z_hi = 0 V'
        write(*,*) 'alpha periodic'
        write(*,*) 'phi0 = ',phi0
        write(*,*) 'Lr   = ',Lr
        write(*,*) 'Lz   = ',Lz
        write(*,*) 'nonuniform stretch qr,qa,qz = ',qr,qa,qz
        write(*,*) '=========================================================='
    end if

    do m = 1,ncase

        call run_uniform_case( &
            nr_list(m), na, nz_list(m), eps0, phi0, rmin, rmax, zmin, zmax, amax, &
            tolerance, err_inf_u(m), err_l2_u(m), save_field=(m==ncase))

        call run_nonuniform_case( &
            nr_list(m), na, nz_list(m), eps0, phi0, rmin, rmax, amin, amax, zmin, zmax, &
            qr, qa, qz, tolerance, err_inf_nu(m), err_l2_nu(m), save_field=(m==ncase))

        if (mpi_i == 0) then
            write(*,*) '----------------------------------------------------------'
            write(*,*) 'grid size: nr = ',nr_list(m),', nz = ',nz_list(m),', na = ',na
            write(*,*) 'uniform   : L_inf = ',err_inf_u(m),'  relL2 = ',err_l2_u(m)
            write(*,*) 'nonuniform: L_inf = ',err_inf_nu(m),'  relL2 = ',err_l2_nu(m)
        end if
    end do

    if (mpi_i == 0) then
        open(unit=301,file='compare_uniform_nonuniform_rz_mms.dat',status='replace',action='write')
        write(301,'(A)') '# N err_inf_uniform err_l2_uniform err_inf_nonuniform err_l2_nonuniform'
        do m = 1,ncase
            write(301,'(I8,1X,4ES24.14)') nr_list(m), err_inf_u(m), err_l2_u(m), &
                err_inf_nu(m), err_l2_nu(m)
        end do
        close(301)
    end if

    call HYPRE_Finalize(ierr_h)

    if (mpi_i == 0) then
        write(*,*) '=========================================================='
        write(*,*) 'Comparison finished.'
        write(*,*) 'Output files:'
        write(*,*) '  compare_uniform_nonuniform_rz_mms.dat'
        write(*,*) '  field_uniform_fine.dat'
        write(*,*) '  field_nonuniform_fine.dat'
        write(*,*) '=========================================================='
    end if

    call mpi_finalize(ierr)

contains

    subroutine exact_phi_rho(r,z,Lr,Lz,phi0,eps0,phi_val,rho_val)
        implicit none
        real,intent(in)  :: r,z,Lr,Lz,phi0,eps0
        real,intent(out) :: phi_val,rho_val
        real :: s,f

        s = r / Lr
        f = s*s - 0.5*s**4

        phi_val = phi0 * f * sin(pi*z/Lz)

        rho_val = eps0 * phi0 * sin(pi*z/Lz) * ( &
            (pi/Lz)**2 * f - ( 4.0/Lr**2 - 8.0*r*r/Lr**4 ) )
    end subroutine exact_phi_rho


    subroutine run_uniform_case(nr,na,nz,eps0,phi0,rmin,rmax,zmin,zmax,amax, &
        tolerance,err_inf,err_l2,save_field)

        implicit none

        integer,intent(in) :: nr,na,nz
        real,intent(in) :: eps0,phi0,rmin,rmax,zmin,zmax,amax,tolerance
        real,intent(out) :: err_inf,err_l2
        logical,intent(in) :: save_field

        integer :: i,j,k,l,nloc,nvalues
        integer :: il(1:3),iu(1:3),periodic(1:3),bc_type(1:6)
        real :: dr,da,dz,Lr,Lz
        real :: r,alpha,z,vol
        real :: bc_value(1:6)
        real :: sum_e2,sum_u2
        logical :: do_init,do_updateA,do_finalize
        integer(8) :: solver,grid,stencil,A,b,x

        real,dimension(:),allocatable :: phi1d,phi_exact,RHS,rho1d,A_values

        il = (/1,1,1/)
        iu = (/nr,na,nz/)

        Lr = rmax - rmin
        Lz = zmax - zmin

        dr = Lr/real(nr)
        da = amax/real(na)
        dz = Lz/real(nz)

        periodic = (/0,na,0/)
        bc_type  = (/BC_AXIS,BC_NEUMANN,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
        bc_value = 0.0
        bc_value(2) = 0.0
        bc_value(5) = 0.0
        bc_value(6) = 0.0

        nloc = nr*na*nz
        nvalues = 7*nloc

        allocate(phi1d(1:nloc),phi_exact(1:nloc),RHS(1:nloc),rho1d(1:nloc),A_values(1:nvalues))

        phi1d = 0.0
        phi_exact = 0.0
        RHS = 0.0
        rho1d = 0.0
        A_values = 0.0

        l = 1
        do k = il(3),iu(3)
        do j = il(2),iu(2)
        do i = il(1),iu(1)
            r = rmin + (real(i)-0.5)*dr
            z = zmin + (real(k)-0.5)*dz
            call exact_phi_rho(r,z,Lr,Lz,phi0,eps0,phi_exact(l),rho1d(l))
            l = l + 1
        end do
        end do
        end do

        call sub_D03_hypre_3Draz_uniform_A(il,iu,rmin,eps0,dr,da,dz,periodic, &
            bc_type,bc_value,A_values,rho1d,RHS)

        do_init = .true.
        do_updateA = .false.
        do_finalize = .false.
        solver = 0_8
        grid = 0_8
        stencil = 0_8
        A = 0_8
        b = 0_8
        x = 0_8

        call sub_D03_hypre_3Draz_uniform(mpi_comm_world,il,iu,phi1d, &
            RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
            solver,grid,stencil,A,b,x)

        do_init = .false.
        do_finalize = .true.
        call sub_D03_hypre_3Draz_uniform(mpi_comm_world,il,iu,phi1d, &
            RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
            solver,grid,stencil,A,b,x)

        err_inf = 0.0
        sum_e2 = 0.0
        sum_u2 = 0.0

        l = 1
        do k = il(3),iu(3)
        do j = il(2),iu(2)
        do i = il(1),iu(1)
            r = rmin + (real(i)-0.5)*dr
            vol = r*dr*da*dz
            err_inf = max(err_inf,abs(phi1d(l)-phi_exact(l)))
            sum_e2 = sum_e2 + (phi1d(l)-phi_exact(l))**2 * vol
            sum_u2 = sum_u2 + phi_exact(l)**2 * vol
            l = l + 1
        end do
        end do
        end do

        err_l2 = sqrt(sum_e2/max(sum_u2,tiny(1.0)))

        if (save_field .and. mpi_i == 0) then
            open(unit=401,file='field_uniform_fine.dat',status='replace',action='write')
            write(401,'(A)') '# i j k r alpha z phi_num phi_exact abs_error'

            l = 1
            do k = il(3),iu(3)
            do j = il(2),iu(2)
            do i = il(1),iu(1)
                r = rmin + (real(i)-0.5)*dr
                alpha = (real(j)-0.5)*da
                z = zmin + (real(k)-0.5)*dz
                write(401,'(3I6,1X,6ES24.14)') i,j,k,r,alpha,z, &
                    phi1d(l),phi_exact(l),abs(phi1d(l)-phi_exact(l))
                l = l + 1
            end do
            end do
            end do

            close(401)
        end if

        deallocate(phi1d,phi_exact,RHS,rho1d,A_values)

    end subroutine run_uniform_case


    subroutine run_nonuniform_case(nr,na,nz,eps0,phi0,rmin,rmax,amin,amax,zmin,zmax, &
        qr,qa,qz,tolerance,err_inf,err_l2,save_field)

        implicit none

        integer,intent(in) :: nr,na,nz
        real,intent(in) :: eps0,phi0,rmin,rmax,amin,amax,zmin,zmax
        real,intent(in) :: qr,qa,qz,tolerance
        real,intent(out) :: err_inf,err_l2
        logical,intent(in) :: save_field

        integer :: i,j,k,l,nloc,nvalues
        integer :: il(1:3),iu(1:3),periodic(1:3),bc_type(1:6)
        real :: Lr,Lz,r,alpha,vol
        real :: bc_value(1:6)
        real :: sum_e2,sum_u2
        logical :: do_init,do_updateA,do_finalize
        integer(8) :: solver,grid,stencil,A,b,x

        real,dimension(:),allocatable :: phi1d,phi_exact,RHS,rho1d,A_values
        real,dimension(:),allocatable :: dr1d,da1d,dz1d
        real,dimension(:),allocatable :: rface,rcell,aface,acell,zface,zcell

        il = (/1,1,1/)
        iu = (/nr,na,nz/)

        Lr = rmax - rmin
        Lz = zmax - zmin

        periodic = (/0,na,0/)
        bc_type  = (/BC_AXIS,BC_NEUMANN,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
        bc_value = 0.0
        bc_value(2) = 0.0
        bc_value(5) = 0.0
        bc_value(6) = 0.0

        nloc = nr*na*nz
        nvalues = 7*nloc

        allocate(phi1d(1:nloc),phi_exact(1:nloc),RHS(1:nloc),rho1d(1:nloc),A_values(1:nvalues))
        allocate(dr1d(il(1):iu(1)),da1d(il(2):iu(2)),dz1d(il(3):iu(3)))
        allocate(rface(il(1)-1:iu(1)),rcell(il(1):iu(1)))
        allocate(aface(il(2)-1:iu(2)),acell(il(2):iu(2)))
        allocate(zface(il(3)-1:iu(3)),zcell(il(3):iu(3)))

        call build_geometric_widths(il(1),iu(1),Lr,qr,dr1d)
        call build_geometric_widths(il(2),iu(2),amax-amin,qa,da1d)
        call build_geometric_widths(il(3),iu(3),Lz,qz,dz1d)

        call build_faces_centers(il(1),iu(1),rmin,dr1d,rface,rcell)
        call build_faces_centers(il(2),iu(2),amin,da1d,aface,acell)
        call build_faces_centers(il(3),iu(3),zmin,dz1d,zface,zcell)

        phi1d = 0.0
        phi_exact = 0.0
        RHS = 0.0
        rho1d = 0.0
        A_values = 0.0

        l = 1
        do k = il(3),iu(3)
        do j = il(2),iu(2)
        do i = il(1),iu(1)
            call exact_phi_rho(rcell(i),zcell(k),Lr,Lz,phi0,eps0,phi_exact(l),rho1d(l))
            l = l + 1
        end do
        end do
        end do

        call sub_D04_hypre_3Draz_nonuniform_A(il,iu,rmin,eps0,dr1d,da1d,dz1d,periodic, &
            bc_type,bc_value,A_values,rho1d,RHS)

        do_init = .true.
        do_updateA = .false.
        do_finalize = .false.
        solver = 0_8
        grid = 0_8
        stencil = 0_8
        A = 0_8
        b = 0_8
        x = 0_8

        call sub_D04_hypre_3Draz_nonuniform(mpi_comm_world,il,iu,phi1d, &
            RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
            solver,grid,stencil,A,b,x)

        do_init = .false.
        do_finalize = .true.
        call sub_D04_hypre_3Draz_nonuniform(mpi_comm_world,il,iu,phi1d, &
            RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
            solver,grid,stencil,A,b,x)

        err_inf = 0.0
        sum_e2 = 0.0
        sum_u2 = 0.0

        l = 1
        do k = il(3),iu(3)
        do j = il(2),iu(2)
        do i = il(1),iu(1)
            r = rcell(i)
            vol = r*dr1d(i)*da1d(j)*dz1d(k)
            err_inf = max(err_inf,abs(phi1d(l)-phi_exact(l)))
            sum_e2 = sum_e2 + (phi1d(l)-phi_exact(l))**2 * vol
            sum_u2 = sum_u2 + phi_exact(l)**2 * vol
            l = l + 1
        end do
        end do
        end do

        err_l2 = sqrt(sum_e2/max(sum_u2,tiny(1.0)))

        if (save_field .and. mpi_i == 0) then
            open(unit=402,file='field_nonuniform_fine.dat',status='replace',action='write')
            write(402,'(A)') '# i j k r alpha z phi_num phi_exact abs_error'

            l = 1
            do k = il(3),iu(3)
            do j = il(2),iu(2)
            do i = il(1),iu(1)
                alpha = acell(j)
                write(402,'(3I6,1X,6ES24.14)') i,j,k,rcell(i),alpha,zcell(k), &
                    phi1d(l),phi_exact(l),abs(phi1d(l)-phi_exact(l))
                l = l + 1
            end do
            end do
            end do

            close(402)
        end if

        deallocate(phi1d,phi_exact,RHS,rho1d,A_values)
        deallocate(dr1d,da1d,dz1d,rface,rcell,aface,acell,zface,zcell)

    end subroutine run_nonuniform_case


    subroutine build_geometric_widths(i1,i2,ltot,q,w)
        implicit none
        integer,intent(in) :: i1,i2
        real,intent(in) :: ltot,q
        real,dimension(i1:i2),intent(out) :: w

        integer :: n,m
        real :: a

        n = i2 - i1 + 1

        if (abs(q-1.0) <= 1.0e-14) then
            do m = i1,i2
                w(m) = ltot/real(n)
            end do
        else
            a = ltot*(q-1.0)/(q**n - 1.0)
            w(i1) = a
            do m = i1+1,i2
                w(m) = w(m-1)*q
            end do
        end if
    end subroutine build_geometric_widths


    subroutine build_faces_centers(i1,i2,xmin,dx,xface,xcell)
        implicit none
        integer,intent(in) :: i1,i2
        real,intent(in) :: xmin
        real,dimension(i1:i2),intent(in) :: dx
        real,dimension(i1-1:i2),intent(out) :: xface
        real,dimension(i1:i2),intent(out) :: xcell
        integer :: m

        xface(i1-1) = xmin
        do m = i1,i2
            xface(m) = xface(m-1) + dx(m)
        end do

        do m = i1,i2
            xcell(m) = 0.5*(xface(m-1) + xface(m))
        end do
    end subroutine build_faces_centers

end program main_compare_uniform_nonuniform_rz_mms