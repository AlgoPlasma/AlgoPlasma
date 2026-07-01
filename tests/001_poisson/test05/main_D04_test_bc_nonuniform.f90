#include "../../../D_Poisson/D04_hypre_3Draz_nonuniform/mod_D04_hypre_3Draz_nonuniform.f90"

program main_D04_test_bc_nonuniform

    use mpi
    use mod_D04_hypre_3Draz_nonuniform
    implicit none
    include "HYPREf.h"

    integer,parameter :: BC_NONE       = 0
    integer,parameter :: BC_AXIS       = 1
    integer,parameter :: BC_DIRICHLET  = 2
    integer,parameter :: BC_NEUMANN    = 3
    integer,parameter :: BC_DIELECTRIC = 4
    integer,parameter :: BC_OUTFLOW    = 5

    real,parameter :: pi = 3.14159265358979323846

    integer :: ierr,ierr_h
    integer :: mpi_i,mpi_n

    integer :: i,j,k,l
    integer :: nr,na,nz,nloc,nvalues
    integer :: il(1:3),iu(1:3),periodic(1:3),bc_type(1:6)

    real :: eps0,rmin,rmax,amin,amax,zmin,zmax,lz,tolerance
    real :: r,alpha,z,vol
    real :: err_inf,err_l2,sum_e2,sum_u2
    real :: phi_infty
    real :: bc_value(1:6)
    real :: r0_cyl(1:3)

    real :: qr,qa,qz

    logical :: do_init,do_updateA,do_finalize
    integer(8) :: solver,grid,stencil,A,b,x

    real,dimension(:),allocatable :: phi1d,phi_exact,RHS,rho1d,A_values
    real,dimension(:),allocatable :: dr1d,da1d,dz1d
    real,dimension(:),allocatable :: rface,rcell,aface,acell,zface,zcell
    real,dimension(:,:),allocatable :: sr_hi

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

    if (mpi_i == 0) then
        write(*,*) '=============================================='
        write(*,*) 'D04 nonuniform-grid quasi-2D (r-z) BC test'
        write(*,*) 'z_lo  = 0 V'
        write(*,*) 'z_hi  = 20 V'
        write(*,*) 'r_lo  = axis'
        write(*,*) 'alpha direction is periodic'
        write(*,*) '=============================================='
    end if

    amin = 0.0
    amax = 2.0*pi
    zmin = 0.0

    ! ============================================================
    ! case 1:
    ! r_lo  = axis
    ! r_hi  = zero Neumann
    ! z_lo  = 0 V
    ! z_hi  = 20 V
    ! alpha periodic
    !
    ! exact solution:
    ! phi(z) = 20 * z / lz
    !
    ! Here z is evaluated at nonuniform cell centers zcell(k).
    ! ============================================================
    nr = 320
    na = 8
    nz = 320

    il = (/1,1,1/)
    iu = (/nr,na,nz/)

    eps0 = 1.0
    rmin = 0.0
    rmax = 2.0
    lz   = 1.0
    zmax = lz
    tolerance = 1.0e-10

    periodic = (/0,na,0/)
    bc_type  = (/BC_AXIS,BC_NEUMANN,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
    bc_value = 0.0
    bc_value(2) = 0.0
    bc_value(5) = 0.0
    bc_value(6) = 20.0

    qr = 1.04
    qa = 1.00
    qz = 1.03

    nloc    = nr*na*nz
    nvalues = 7*nloc

    allocate(phi1d(1:nloc),phi_exact(1:nloc),RHS(1:nloc),rho1d(1:nloc),A_values(1:nvalues))
    allocate(dr1d(il(1):iu(1)),da1d(il(2):iu(2)),dz1d(il(3):iu(3)))
    allocate(rface(il(1)-1:iu(1)),rcell(il(1):iu(1)))
    allocate(aface(il(2)-1:iu(2)),acell(il(2):iu(2)))
    allocate(zface(il(3)-1:iu(3)),zcell(il(3):iu(3)))

    call build_geometric_widths(il(1),iu(1),rmax-rmin,qr,dr1d)
    call build_geometric_widths(il(2),iu(2),amax-amin,qa,da1d)
    call build_geometric_widths(il(3),iu(3),zmax-zmin,qz,dz1d)

    call build_faces_centers(il(1),iu(1),rmin,dr1d,rface,rcell)
    call build_faces_centers(il(2),iu(2),amin,da1d,aface,acell)
    call build_faces_centers(il(3),iu(3),zmin,dz1d,zface,zcell)

    phi1d = 0.0
    phi_exact = 0.0
    rho1d = 0.0
    RHS = 0.0
    A_values = 0.0

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

    l = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        z = zcell(k)
        phi_exact(l) = 20.0*z/lz
        l = l + 1
    end do
    end do
    end do

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

    if (mpi_i == 0) then
        write(*,*) '----------------------------------------------'
        write(*,*) 'case 1: exact test on nonuniform mesh'
        write(*,*) 'z_lo = 0 V, z_hi = 20 V'
        write(*,*) 'r_lo = axis, r_hi = zero Neumann'
        write(*,*) 'alpha = periodic'
        write(*,*) 'exact phi(z) = 20*z/lz'
        write(*,*) 'stretch ratios qr,qa,qz = ',qr,qa,qz
        write(*,*) 'L_inf error     = ',err_inf
        write(*,*) 'relative L2 err = ',err_l2

        open(unit=201,file='case1_nonuniform_phi_compare.dat',status='replace',action='write')
        write(201,'(A)') '# i j k r alpha z phi_num phi_exact abs_error'

        l = 1
        do k = il(3),iu(3)
        do j = il(2),iu(2)
        do i = il(1),iu(1)
            write(201,'(3I6,1X,6ES24.14)') i,j,k,rcell(i),acell(j),zcell(k), &
                phi1d(l),phi_exact(l),abs(phi1d(l)-phi_exact(l))
            l = l + 1
        end do
        end do
        end do

        close(201)
    end if

    deallocate(phi1d,phi_exact,RHS,rho1d,A_values)
    deallocate(dr1d,da1d,dz1d,rface,rcell,aface,acell,zface,zcell)

    ! ============================================================
    ! case 2:
    ! r_lo  = axis
    ! r_hi  = dielectric
    ! z_lo  = 0 V
    ! z_hi  = 20 V
    ! alpha periodic
    ! ============================================================
    nr = 240
    na = 8
    nz = 240

    il = (/1,1,1/)
    iu = (/nr,na,nz/)

    eps0 = 1.0
    rmin = 0.0
    rmax = 2.0
    lz   = 1.0
    zmax = lz
    tolerance = 1.0e-10

    periodic = (/0,na,0/)
    bc_type  = (/BC_AXIS,BC_DIELECTRIC,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
    bc_value = 0.0
    bc_value(5) = 0.0
    bc_value(6) = 20.0

    qr = 1.05
    qa = 1.00
    qz = 1.04

    nloc    = nr*na*nz
    nvalues = 7*nloc

    allocate(phi1d(1:nloc),RHS(1:nloc),rho1d(1:nloc),A_values(1:nvalues))
    allocate(dr1d(il(1):iu(1)),da1d(il(2):iu(2)),dz1d(il(3):iu(3)))
    allocate(rface(il(1)-1:iu(1)),rcell(il(1):iu(1)))
    allocate(aface(il(2)-1:iu(2)),acell(il(2):iu(2)))
    allocate(zface(il(3)-1:iu(3)),zcell(il(3):iu(3)))
    allocate(sr_hi(il(2)-1:iu(2),il(3)-1:iu(3)))

    call build_geometric_widths(il(1),iu(1),rmax-rmin,qr,dr1d)
    call build_geometric_widths(il(2),iu(2),amax-amin,qa,da1d)
    call build_geometric_widths(il(3),iu(3),zmax-zmin,qz,dz1d)

    call build_faces_centers(il(1),iu(1),rmin,dr1d,rface,rcell)
    call build_faces_centers(il(2),iu(2),amin,da1d,aface,acell)
    call build_faces_centers(il(3),iu(3),zmin,dz1d,zface,zcell)

    phi1d = 0.0
    rho1d = 0.0
    RHS = 0.0
    A_values = 0.0
    sr_hi = 1.0e-3

    call sub_D04_hypre_3Draz_nonuniform_A(il,iu,rmin,eps0,dr1d,da1d,dz1d,periodic, &
        bc_type,bc_value,A_values,rho1d,RHS)

    call sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric(il,iu,A_values,RHS,bc_type, &
        sr_hi=sr_hi)

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

    if (mpi_i == 0) then
        write(*,*) '----------------------------------------------'
        write(*,*) 'case 2: dielectric smoke test on nonuniform mesh'
        write(*,*) 'z_lo = 0 V, z_hi = 20 V'
        write(*,*) 'r_lo = axis, r_hi = dielectric'
        write(*,*) 'stretch ratios qr,qa,qz = ',qr,qa,qz
        write(*,*) 'min(phi) = ',minval(phi1d)
        write(*,*) 'max(phi) = ',maxval(phi1d)
        write(*,*) 'max|phi| = ',maxval(abs(phi1d))

        open(unit=202,file='case2_nonuniform_phi_only.dat',status='replace',action='write')
        write(202,'(A)') '# i j k r alpha z phi_num'

        l = 1
        do k = il(3),iu(3)
        do j = il(2),iu(2)
        do i = il(1),iu(1)
            write(202,'(3I6,1X,4ES24.14)') i,j,k,rcell(i),acell(j),zcell(k),phi1d(l)
            l = l + 1
        end do
        end do
        end do

        close(202)
    end if

    deallocate(phi1d,RHS,rho1d,A_values)
    deallocate(dr1d,da1d,dz1d,rface,rcell,aface,acell,zface,zcell,sr_hi)

    ! ============================================================
    ! case 3:
    ! r_lo  = axis
    ! r_hi  = outflow
    ! z_lo  = 0 V
    ! z_hi  = 20 V
    ! alpha periodic
    ! ============================================================
    nr = 240
    na = 8
    nz = 240

    il = (/1,1,1/)
    iu = (/nr,na,nz/)

    eps0 = 1.0
    rmin = 0.0
    rmax = 2.0
    lz   = 1.0
    zmax = lz
    tolerance = 1.0e-10

    periodic = (/0,na,0/)
    bc_type  = (/BC_AXIS,BC_OUTFLOW,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
    bc_value = 0.0
    bc_value(5) = 0.0
    bc_value(6) = 20.0

    phi_infty = 20.0
    r0_cyl = (/0.0,0.0,-10.0/)

    qr = 1.05
    qa = 1.00
    qz = 1.04

    nloc    = nr*na*nz
    nvalues = 7*nloc

    allocate(phi1d(1:nloc),RHS(1:nloc),rho1d(1:nloc),A_values(1:nvalues))
    allocate(dr1d(il(1):iu(1)),da1d(il(2):iu(2)),dz1d(il(3):iu(3)))
    allocate(rface(il(1)-1:iu(1)),rcell(il(1):iu(1)))
    allocate(aface(il(2)-1:iu(2)),acell(il(2):iu(2)))
    allocate(zface(il(3)-1:iu(3)),zcell(il(3):iu(3)))

    call build_geometric_widths(il(1),iu(1),rmax-rmin,qr,dr1d)
    call build_geometric_widths(il(2),iu(2),amax-amin,qa,da1d)
    call build_geometric_widths(il(3),iu(3),zmax-zmin,qz,dz1d)

    call build_faces_centers(il(1),iu(1),rmin,dr1d,rface,rcell)
    call build_faces_centers(il(2),iu(2),amin,da1d,aface,acell)
    call build_faces_centers(il(3),iu(3),zmin,dz1d,zface,zcell)

    phi1d = 0.0
    rho1d = 0.0
    RHS = 0.0
    A_values = 0.0

    call sub_D04_hypre_3Draz_nonuniform_A(il,iu,rmin,eps0,dr1d,da1d,dz1d,periodic, &
        bc_type,bc_value,A_values,rho1d,RHS)

    call sub_D04_hypre_3Draz_nonuniform_bc_A_outflow(il,iu,rmin,amin,zmin,dr1d,da1d,dz1d, &
        bc_type,A_values,RHS,phi_infty,r0_cyl)

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

    if (mpi_i == 0) then
        write(*,*) '----------------------------------------------'
        write(*,*) 'case 3: outflow smoke test on nonuniform mesh'
        write(*,*) 'z_lo = 0 V, z_hi = 20 V'
        write(*,*) 'r_lo = axis, r_hi = outflow'
        write(*,*) 'stretch ratios qr,qa,qz = ',qr,qa,qz
        write(*,*) 'min(phi) = ',minval(phi1d)
        write(*,*) 'max(phi) = ',maxval(phi1d)
        write(*,*) 'max|phi| = ',maxval(abs(phi1d))

        open(unit=203,file='case3_nonuniform_phi_only.dat',status='replace',action='write')
        write(203,'(A)') '# i j k r alpha z phi_num'

        l = 1
        do k = il(3),iu(3)
        do j = il(2),iu(2)
        do i = il(1),iu(1)
            write(203,'(3I6,1X,4ES24.14)') i,j,k,rcell(i),acell(j),zcell(k),phi1d(l)
            l = l + 1
        end do
        end do
        end do

        close(203)
    end if

    deallocate(phi1d,RHS,rho1d,A_values)
    deallocate(dr1d,da1d,dz1d,rface,rcell,aface,acell,zface,zcell)

    call HYPRE_Finalize(ierr_h)

    if (mpi_i == 0) then
        write(*,*) '=============================================='
        write(*,*) 'All nonuniform boundary-condition tests finished.'
        write(*,*) '=============================================='
    end if

    call mpi_finalize(ierr)

contains

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

end program main_D04_test_bc_nonuniform
