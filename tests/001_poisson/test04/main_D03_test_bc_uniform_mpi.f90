#include "../../../D_Poisson/D03_hypre_3Draz_uniform/mod_D03_hypre_3Draz_uniform.f90"

program main_D03_test_bc_uniform_mpi

    use mpi
    use mod_D03_hypre_3Draz_uniform
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
    integer :: cart_comm,fcomm

    integer :: dims(1:3),coords(1:3)
    logical :: periods_log(1:3),reorder

    integer :: nbr_r_lo,nbr_r_hi,nbr_a_lo,nbr_a_hi,nbr_z_lo,nbr_z_hi
    logical :: has_neighbor(1:6)

    integer :: nr,na,nz,nloc,nvalues
    integer :: il_loc(1:3),iu_loc(1:3)
    integer :: il_tmp(1:3),iu_tmp(1:3)
    integer :: periodic(1:3),bc_type(1:6),bc_post(1:6)

    integer :: i,j,k,l
    integer :: p,nbuf_recv
    integer :: header(6),status(MPI_STATUS_SIZE)

    real :: eps0,rmin,rmax,lz,dr,da,dz,tolerance
    real :: r,alpha,z,vol
    real :: err_inf_loc,err_inf,err_l2_loc,err_l2,ref_l2_loc,ref_l2
    real :: phi_ex
    real :: rface_lo,amin_lo,zmin_lo
    real :: phi_infty
    real :: bc_value(1:6)
    real :: r0_cyl(1:3)

    logical :: do_init,do_updateA,do_finalize
    integer(8) :: solver,grid,stencil,A,b,x

    real,dimension(:),allocatable :: phi1d,RHS,rho1d,A_values
    real,dimension(:),allocatable :: phi_buf
    real,dimension(:,:),allocatable :: sr_hi

    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
    call mpi_comm_size(mpi_comm_world,mpi_n,ierr)

    dims = 0
    call mpi_dims_create(mpi_n,3,dims,ierr)

    periods_log = (/ .false., .true., .false. /)
    reorder = .false.
    call mpi_cart_create(mpi_comm_world,3,dims,periods_log,reorder,cart_comm,ierr)
    fcomm = cart_comm

    call mpi_comm_rank(cart_comm,mpi_i,ierr)
    call mpi_comm_size(cart_comm,mpi_n,ierr)
    call mpi_cart_coords(cart_comm,mpi_i,3,coords,ierr)

    call mpi_cart_shift(cart_comm,0,1,nbr_r_lo,nbr_r_hi,ierr)
    call mpi_cart_shift(cart_comm,1,1,nbr_a_lo,nbr_a_hi,ierr)
    call mpi_cart_shift(cart_comm,2,1,nbr_z_lo,nbr_z_hi,ierr)

    has_neighbor(1) = (nbr_r_lo /= MPI_PROC_NULL)
    has_neighbor(2) = (nbr_r_hi /= MPI_PROC_NULL)
    has_neighbor(3) = (nbr_a_lo /= MPI_PROC_NULL)
    has_neighbor(4) = (nbr_a_hi /= MPI_PROC_NULL)
    has_neighbor(5) = (nbr_z_lo /= MPI_PROC_NULL)
    has_neighbor(6) = (nbr_z_hi /= MPI_PROC_NULL)

    call HYPRE_Initialize(ierr_h)

    if (mpi_i == 0) then
        write(*,*) '=============================================='
        write(*,*) 'D03 uniform-grid quasi-2D (r-z) BC test (MPI)'
        write(*,*) 'z_lo  = 0 V'
        write(*,*) 'z_hi  = 20 V'
        write(*,*) 'r_lo  = axis'
        write(*,*) 'alpha direction is periodic'
        write(*,*) 'MPI ranks       = ',mpi_n
        write(*,*) 'MPI dims(r,a,z) = ',dims
        write(*,*) '=============================================='
    end if

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
    ! ============================================================
    nr = 320
    na = 8
    nz = 320

    call partition_1d(nr,dims(1),coords(1),il_loc(1),iu_loc(1))
    call partition_1d(na,dims(2),coords(2),il_loc(2),iu_loc(2))
    call partition_1d(nz,dims(3),coords(3),il_loc(3),iu_loc(3))

    eps0 = 1.0
    rmin = 0.0
    rmax = 2.0
    lz = 1.0
    dr = (rmax-rmin)/real(nr)
    da = 2.0*pi/real(na)
    dz = lz/real(nz)
    tolerance = 1.0e-10

    periodic = (/0,na,0/)
    bc_type = (/BC_AXIS,BC_NEUMANN,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
    bc_value = 0.0
    bc_value(2) = 0.0
    bc_value(5) = 0.0
    bc_value(6) = 20.0

    rface_lo = rmin + real(il_loc(1)-1)*dr

    nloc = (iu_loc(1)-il_loc(1)+1)*(iu_loc(2)-il_loc(2)+1)*(iu_loc(3)-il_loc(3)+1)
    nvalues = 7*nloc

    allocate(phi1d(1:nloc),RHS(1:nloc),rho1d(1:nloc),A_values(1:nvalues))

    phi1d = 0.0
    rho1d = 0.0
    RHS = 0.0
    A_values = 0.0

    call sub_D03_hypre_3Draz_uniform_A_mpi(il_loc,iu_loc,rface_lo,eps0,dr,da,dz, &
        periodic,has_neighbor,bc_type,bc_value,A_values,rho1d,RHS)

    do_init = .true.
    do_updateA = .false.
    do_finalize = .false.
    solver = 0_8
    grid = 0_8
    stencil = 0_8
    A = 0_8
    b = 0_8
    x = 0_8

    call sub_D03_hypre_3Draz_uniform(fcomm,il_loc,iu_loc,phi1d, &
        RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
        solver,grid,stencil,A,b,x)

    do_init = .false.
    do_finalize = .true.
    call sub_D03_hypre_3Draz_uniform(fcomm,il_loc,iu_loc,phi1d, &
        RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
        solver,grid,stencil,A,b,x)

    err_inf_loc = 0.0
    err_l2_loc = 0.0
    ref_l2_loc = 0.0

    l = 1
    do k = il_loc(3),iu_loc(3)
    do j = il_loc(2),iu_loc(2)
    do i = il_loc(1),iu_loc(1)
        r = rmin + (real(i)-0.5)*dr
        z = (real(k)-0.5)*dz
        phi_ex = 20.0*z/lz
        vol = r*dr*da*dz

        err_inf_loc = max(err_inf_loc,abs(phi1d(l)-phi_ex))
        err_l2_loc = err_l2_loc + (phi1d(l)-phi_ex)**2 * vol
        ref_l2_loc = ref_l2_loc + phi_ex*phi_ex*vol

        l = l + 1
    end do
    end do
    end do

    call mpi_reduce(err_inf_loc,err_inf,1,MPI_DOUBLE_PRECISION,MPI_MAX,0,cart_comm,ierr)
    call mpi_reduce(err_l2_loc,err_l2,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,cart_comm,ierr)
    call mpi_reduce(ref_l2_loc,ref_l2,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,cart_comm,ierr)

    if (mpi_i == 0) then
        err_l2 = sqrt(err_l2/max(ref_l2,tiny(1.0d0)))
        write(*,*) '----------------------------------------------'
        write(*,*) 'case 1: exact test'
        write(*,*) 'z_lo = 0 V, z_hi = 20 V'
        write(*,*) 'r_lo = axis, r_hi = zero Neumann'
        write(*,*) 'alpha = periodic'
        write(*,*) 'exact phi(z) = 20*z/lz'
        write(*,*) 'L_inf error     = ',err_inf
        write(*,*) 'relative L2 err = ',err_l2
    end if

    call write_compare_file_mpi('case1_phi_compare.dat',cart_comm,mpi_i,mpi_n, &
        il_loc,iu_loc,rmin,dr,da,dz,lz,phi1d)

    deallocate(phi1d,RHS,rho1d,A_values)

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

    call partition_1d(nr,dims(1),coords(1),il_loc(1),iu_loc(1))
    call partition_1d(na,dims(2),coords(2),il_loc(2),iu_loc(2))
    call partition_1d(nz,dims(3),coords(3),il_loc(3),iu_loc(3))

    eps0 = 1.0
    rmin = 0.0
    rmax = 2.0
    lz = 1.0
    dr = (rmax-rmin)/real(nr)
    da = 2.0*pi/real(na)
    dz = lz/real(nz)
    tolerance = 1.0e-10

    periodic = (/0,na,0/)
    bc_type = (/BC_AXIS,BC_DIELECTRIC,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
    bc_value = 0.0
    bc_value(5) = 0.0
    bc_value(6) = 20.0

    bc_post = BC_NONE
    if (.not. has_neighbor(2)) bc_post(2) = BC_DIELECTRIC

    rface_lo = rmin + real(il_loc(1)-1)*dr

    nloc = (iu_loc(1)-il_loc(1)+1)*(iu_loc(2)-il_loc(2)+1)*(iu_loc(3)-il_loc(3)+1)
    nvalues = 7*nloc

    allocate(phi1d(1:nloc),RHS(1:nloc),rho1d(1:nloc),A_values(1:nvalues))
    allocate(sr_hi(il_loc(2)-1:iu_loc(2),il_loc(3)-1:iu_loc(3)))

    phi1d = 0.0
    rho1d = 0.0
    RHS = 0.0
    A_values = 0.0
    sr_hi = 1.0e-3

    call sub_D03_hypre_3Draz_uniform_A_mpi(il_loc,iu_loc,rface_lo,eps0,dr,da,dz, &
        periodic,has_neighbor,bc_type,bc_value,A_values,rho1d,RHS)

    call sub_D03_hypre_3Draz_uniform_bc_A_dielectric(il_loc,iu_loc,A_values,RHS,bc_post, &
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

    call sub_D03_hypre_3Draz_uniform(fcomm,il_loc,iu_loc,phi1d, &
        RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
        solver,grid,stencil,A,b,x)

    do_init = .false.
    do_finalize = .true.
    call sub_D03_hypre_3Draz_uniform(fcomm,il_loc,iu_loc,phi1d, &
        RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
        solver,grid,stencil,A,b,x)

    if (mpi_i == 0) then
        write(*,*) '----------------------------------------------'
        write(*,*) 'case 2: dielectric smoke test'
        write(*,*) 'z_lo = 0 V, z_hi = 20 V'
        write(*,*) 'r_lo = axis, r_hi = dielectric'
    end if

    call write_phi_only_file_mpi('case2_phi_only.dat',cart_comm,mpi_i,mpi_n, &
        il_loc,iu_loc,rmin,dr,da,dz,phi1d)

    deallocate(phi1d,RHS,rho1d,A_values,sr_hi)

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

    call partition_1d(nr,dims(1),coords(1),il_loc(1),iu_loc(1))
    call partition_1d(na,dims(2),coords(2),il_loc(2),iu_loc(2))
    call partition_1d(nz,dims(3),coords(3),il_loc(3),iu_loc(3))

    eps0 = 1.0
    rmin = 0.0
    rmax = 2.0
    lz = 1.0
    dr = (rmax-rmin)/real(nr)
    da = 2.0*pi/real(na)
    dz = lz/real(nz)
    tolerance = 1.0e-10

    periodic = (/0,na,0/)
    bc_type = (/BC_AXIS,BC_OUTFLOW,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
    bc_value = 0.0
    bc_value(5) = 0.0
    bc_value(6) = 20.0

    bc_post = BC_NONE
    if (.not. has_neighbor(2)) bc_post(2) = BC_OUTFLOW

    phi_infty = 20.0
    r0_cyl = (/0.0,0.0,-10.0/)

    rface_lo = rmin + real(il_loc(1)-1)*dr
    amin_lo = real(il_loc(2)-1)*da
    zmin_lo = real(il_loc(3)-1)*dz

    nloc = (iu_loc(1)-il_loc(1)+1)*(iu_loc(2)-il_loc(2)+1)*(iu_loc(3)-il_loc(3)+1)
    nvalues = 7*nloc

    allocate(phi1d(1:nloc),RHS(1:nloc),rho1d(1:nloc),A_values(1:nvalues))

    phi1d = 0.0
    rho1d = 0.0
    RHS = 0.0
    A_values = 0.0

    call sub_D03_hypre_3Draz_uniform_A_mpi(il_loc,iu_loc,rface_lo,eps0,dr,da,dz, &
        periodic,has_neighbor,bc_type,bc_value,A_values,rho1d,RHS)

    call sub_D03_hypre_3Draz_uniform_bc_A_outflow(il_loc,iu_loc,rface_lo,amin_lo,zmin_lo, &
        dr,da,dz,A_values,RHS,bc_post,phi_infty,r0_cyl)

    do_init = .true.
    do_updateA = .false.
    do_finalize = .false.
    solver = 0_8
    grid = 0_8
    stencil = 0_8
    A = 0_8
    b = 0_8
    x = 0_8

    call sub_D03_hypre_3Draz_uniform(fcomm,il_loc,iu_loc,phi1d, &
        RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
        solver,grid,stencil,A,b,x)

    do_init = .false.
    do_finalize = .true.
    call sub_D03_hypre_3Draz_uniform(fcomm,il_loc,iu_loc,phi1d, &
        RHS,tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
        solver,grid,stencil,A,b,x)

    if (mpi_i == 0) then
        write(*,*) '----------------------------------------------'
        write(*,*) 'case 3: outflow smoke test'
        write(*,*) 'z_lo = 0 V, z_hi = 20 V'
        write(*,*) 'r_lo = axis, r_hi = outflow'
    end if

    call write_phi_only_file_mpi('case3_phi_only.dat',cart_comm,mpi_i,mpi_n, &
        il_loc,iu_loc,rmin,dr,da,dz,phi1d)

    deallocate(phi1d,RHS,rho1d,A_values)

    call HYPRE_Finalize(ierr_h)

    if (mpi_i == 0) then
        write(*,*) '=============================================='
        write(*,*) 'All boundary-condition tests finished.'
        write(*,*) '=============================================='
    end if

    call mpi_finalize(ierr)

contains

    subroutine partition_1d(n_global,n_parts,coord,ilo,ihi)
        implicit none
        integer,intent(in) :: n_global,n_parts,coord
        integer,intent(out) :: ilo,ihi
        integer :: base,rem_1d,n_local

        base = n_global / n_parts
        rem_1d = mod(n_global,n_parts)

        if (coord < rem_1d) then
            n_local = base + 1
            ilo = coord*n_local + 1
        else
            n_local = base
            ilo = rem_1d*(base+1) + (coord-rem_1d)*base + 1
        end if

        ihi = ilo + n_local - 1
    end subroutine partition_1d

    subroutine write_compare_file_mpi(filename,comm,rank,nproc,il_box,iu_box,rmin,dr,da,dz,lz,phi_local)
        implicit none
        character(len=*),intent(in) :: filename
        integer,intent(in) :: comm,rank,nproc
        integer,intent(in) :: il_box(1:3),iu_box(1:3)
        real,intent(in) :: rmin,dr,da,dz,lz
        real,dimension(:),intent(in) :: phi_local

        integer :: ierr_loc
        integer :: p,nbuf_recv
        integer :: ii,jj,kk,ll
        integer :: header_loc(6),status_loc(MPI_STATUS_SIZE)
        real :: r_loc,alpha_loc,z_loc,phi_ex
        real,dimension(:),allocatable :: phi_buf

        if (rank == 0) then
            open(unit=201,file=filename,status='replace',action='write')
            write(201,'(A)') '# i j k r alpha z phi_num phi_exact abs_error'

            ll = 1
            do kk = il_box(3),iu_box(3)
            do jj = il_box(2),iu_box(2)
            do ii = il_box(1),iu_box(1)
                r_loc = rmin + (real(ii)-0.5)*dr
                alpha_loc = (real(jj)-0.5)*da
                z_loc = (real(kk)-0.5)*dz
                phi_ex = 20.0*z_loc/lz
                write(201,'(3I6,1X,6ES24.14)') ii,jj,kk,r_loc,alpha_loc,z_loc, &
                    phi_local(ll),phi_ex,abs(phi_local(ll)-phi_ex)
                ll = ll + 1
            end do
            end do
            end do

            do p = 1,nproc-1
                call mpi_recv(header_loc,6,MPI_INTEGER,p,401,comm,status_loc,ierr_loc)
                nbuf_recv = (header_loc(2)-header_loc(1)+1) * &
                            (header_loc(4)-header_loc(3)+1) * &
                            (header_loc(6)-header_loc(5)+1)
                allocate(phi_buf(1:nbuf_recv))
                call mpi_recv(phi_buf,nbuf_recv,MPI_DOUBLE_PRECISION,p,402,comm,status_loc,ierr_loc)

                ll = 1
                do kk = header_loc(5),header_loc(6)
                do jj = header_loc(3),header_loc(4)
                do ii = header_loc(1),header_loc(2)
                    r_loc = rmin + (real(ii)-0.5)*dr
                    alpha_loc = (real(jj)-0.5)*da
                    z_loc = (real(kk)-0.5)*dz
                    phi_ex = 20.0*z_loc/lz
                    write(201,'(3I6,1X,6ES24.14)') ii,jj,kk,r_loc,alpha_loc,z_loc, &
                        phi_buf(ll),phi_ex,abs(phi_buf(ll)-phi_ex)
                    ll = ll + 1
                end do
                end do
                end do

                deallocate(phi_buf)
            end do

            close(201)
        else
            header_loc = (/il_box(1),iu_box(1),il_box(2),iu_box(2),il_box(3),iu_box(3)/)
            call mpi_send(header_loc,6,MPI_INTEGER,0,401,comm,ierr_loc)
            call mpi_send(phi_local,size(phi_local),MPI_DOUBLE_PRECISION,0,402,comm,ierr_loc)
        end if
    end subroutine write_compare_file_mpi

    subroutine write_phi_only_file_mpi(filename,comm,rank,nproc,il_box,iu_box,rmin,dr,da,dz,phi_local)
        implicit none
        character(len=*),intent(in) :: filename
        integer,intent(in) :: comm,rank,nproc
        integer,intent(in) :: il_box(1:3),iu_box(1:3)
        real,intent(in) :: rmin,dr,da,dz
        real,dimension(:),intent(in) :: phi_local

        integer :: ierr_loc
        integer :: p,nbuf_recv
        integer :: ii,jj,kk,ll
        integer :: header_loc(6),status_loc(MPI_STATUS_SIZE)
        real :: r_loc,alpha_loc,z_loc
        real,dimension(:),allocatable :: phi_buf

        if (rank == 0) then
            open(unit=202,file=filename,status='replace',action='write')
            write(202,'(A)') '# i j k r alpha z phi_num'

            ll = 1
            do kk = il_box(3),iu_box(3)
            do jj = il_box(2),iu_box(2)
            do ii = il_box(1),iu_box(1)
                r_loc = rmin + (real(ii)-0.5)*dr
                alpha_loc = (real(jj)-0.5)*da
                z_loc = (real(kk)-0.5)*dz
                write(202,'(3I6,1X,4ES24.14)') ii,jj,kk,r_loc,alpha_loc,z_loc,phi_local(ll)
                ll = ll + 1
            end do
            end do
            end do

            do p = 1,nproc-1
                call mpi_recv(header_loc,6,MPI_INTEGER,p,411,comm,status_loc,ierr_loc)
                nbuf_recv = (header_loc(2)-header_loc(1)+1) * &
                            (header_loc(4)-header_loc(3)+1) * &
                            (header_loc(6)-header_loc(5)+1)
                allocate(phi_buf(1:nbuf_recv))
                call mpi_recv(phi_buf,nbuf_recv,MPI_DOUBLE_PRECISION,p,412,comm,status_loc,ierr_loc)

                ll = 1
                do kk = header_loc(5),header_loc(6)
                do jj = header_loc(3),header_loc(4)
                do ii = header_loc(1),header_loc(2)
                    r_loc = rmin + (real(ii)-0.5)*dr
                    alpha_loc = (real(jj)-0.5)*da
                    z_loc = (real(kk)-0.5)*dz
                    write(202,'(3I6,1X,4ES24.14)') ii,jj,kk,r_loc,alpha_loc,z_loc,phi_buf(ll)
                    ll = ll + 1
                end do
                end do
                end do

                deallocate(phi_buf)
            end do

            close(202)
        else
            header_loc = (/il_box(1),iu_box(1),il_box(2),iu_box(2),il_box(3),iu_box(3)/)
            call mpi_send(header_loc,6,MPI_INTEGER,0,411,comm,ierr_loc)
            call mpi_send(phi_local,size(phi_local),MPI_DOUBLE_PRECISION,0,412,comm,ierr_loc)
        end if
    end subroutine write_phi_only_file_mpi

end program main_D03_test_bc_uniform_mpi
