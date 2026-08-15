#include "../../../D_Poisson/D04_hypre_3Draz_nonuniform/mod_D04_hypre_3Draz_nonuniform.f90"

program main_D04_test_multi_mpi_raz

    use mpi
    use mod_D04_hypre_3Draz_nonuniform
    implicit none
    include "HYPREf.h"

    integer,parameter :: BC_NONE = 0
    integer,parameter :: BC_AXIS = 1
    integer,parameter :: BC_DIRICHLET = 2
    integer,parameter :: BC_NEUMANN = 3
    integer,parameter :: BC_ROBIN = 4

    real,parameter :: pi = 3.14159265358979323846
    real,parameter :: j1_zero_1 = 3.8317059702075123156

    integer :: ierr,ierr_h
    integer :: mpi_i,mpi_n
    integer :: cart_comm,fcomm
    integer :: p
    integer :: nr,na,nz
    integer :: i,j,k,l
    integer :: nloc,nr_loc,na_loc,nz_loc
    integer :: nbuf_recv
    integer :: nbr_r_lo,nbr_r_hi,nbr_a_lo,nbr_a_hi,nbr_z_lo,nbr_z_hi
    integer :: header(6),status(MPI_STATUS_SIZE)
    integer :: dims(1:3),coords(1:3),coords_p(1:3)
    integer :: il_loc(1:3),iu_loc(1:3),periodic(1:3)
    integer :: bc_type(1:6)
    integer :: il_tmp(1:3),iu_tmp(1:3)
    logical :: periods_log(1:3),reorder
    logical :: has_neighbor(1:6)

    real :: eps0,rmin,rmax,lz,tolerance
    real :: da0
    real :: beta_r,beta_z
    real :: s,wsum
    real :: kappa,mu
    real :: r,alpha,z,vol
    real :: phi_ex,rho_ex,diff
    real :: err_linf_loc,err_linf,err_l2_loc,err_l2,ref_l2_loc,ref_l2
    real :: rface_lo
    real :: bc_value(1:6)

    real,dimension(:),allocatable :: dr_global,da_global,dz_global
    real,dimension(:),allocatable :: wr,wz
    real,dimension(:),allocatable :: rcell_global,zcell_global
    real,dimension(:),allocatable :: rface_global,zface_global
    real,dimension(:),allocatable :: dr,da,dz
    real,dimension(:),allocatable :: phi1d,phi_exact,rho1d,RHS,A_values
    real,dimension(:),allocatable :: phi_buf,phi_exact_buf
    real,dimension(:,:,:),allocatable :: phi_all,phi_exact_all

    logical :: do_init,do_updateA,do_finalize
    integer(8) :: solver,grid,stencil,A,b,x

    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
    call mpi_comm_size(mpi_comm_world,mpi_n,ierr)

    ! ------------------------------------------------------------
    ! Analytic test, same exact solution as the single-rank case:
    !   phi(r,alpha,z) = J1(kappa*r)*cos(alpha)*sin(pi*z/Lz)
    !
    ! In this version, MPI decomposition is applied simultaneously in
    ! r, alpha, and z. Each rank owns one local box in global index
    ! space and exchanges one ghost width in every direction for the
    ! MPI-local matrix assembly routine
    ! sub_D04_hypre_3Draz_nonuniform_A_mpi.
    ! ------------------------------------------------------------
    nr = 32
    na = 16
    nz = 32

    dims = (/2,2,2/)

    periods_log = (/ .false., .true., .false. /)
    reorder = .false.
    call mpi_cart_create(mpi_comm_world,3,dims,periods_log,reorder,cart_comm,ierr)
    fcomm = cart_comm

    call mpi_comm_rank(cart_comm,mpi_i,ierr)
    call mpi_cart_coords(cart_comm,mpi_i,3,coords,ierr)

    call partition_1d(nr,dims(1),coords(1),il_loc(1),iu_loc(1))
    call partition_1d(na,dims(2),coords(2),il_loc(2),iu_loc(2))
    call partition_1d(nz,dims(3),coords(3),il_loc(3),iu_loc(3))

    nr_loc = iu_loc(1)-il_loc(1)+1
    na_loc = iu_loc(2)-il_loc(2)+1
    nz_loc = iu_loc(3)-il_loc(3)+1
    nloc = nr_loc*na_loc*nz_loc

    eps0 = 1.0
    rmin = 0.0
    rmax = 1.0
    lz = 1.0
    tolerance = 1.0e-10

    periodic = (/0,na,0/)
    bc_type = (/BC_AXIS,BC_DIRICHLET,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
    bc_value = 0.0

    call mpi_cart_shift(cart_comm,0,1,nbr_r_lo,nbr_r_hi,ierr)
    call mpi_cart_shift(cart_comm,1,1,nbr_a_lo,nbr_a_hi,ierr)
    call mpi_cart_shift(cart_comm,2,1,nbr_z_lo,nbr_z_hi,ierr)

    has_neighbor(1) = (nbr_r_lo /= MPI_PROC_NULL)
    has_neighbor(2) = (nbr_r_hi /= MPI_PROC_NULL)
    has_neighbor(3) = (nbr_a_lo /= MPI_PROC_NULL)
    has_neighbor(4) = (nbr_a_hi /= MPI_PROC_NULL)
    has_neighbor(5) = (nbr_z_lo /= MPI_PROC_NULL)
    has_neighbor(6) = (nbr_z_hi /= MPI_PROC_NULL)

    da0 = 2.0*pi/real(na)

    allocate(dr_global(1:nr))
    allocate(da_global(1:na))
    allocate(dz_global(1:nz))
    allocate(wr(1:nr))
    allocate(wz(1:nz))
    allocate(rcell_global(1:nr))
    allocate(zcell_global(1:nz))
    allocate(rface_global(0:nr))
    allocate(zface_global(0:nz))

    ! ------------------------------------------------------------
    ! Build the same global mesh on every rank, then slice out the
    ! local owned ranges and exchange one ghost width in each direction.
    ! ------------------------------------------------------------
    beta_r = 4.0
    if (nr == 1) then
        wr(1) = 1.0
    else
        do i = 1,nr
            s = real(i-1)/real(nr-1)
            wr(i) = 1.0 + beta_r*s*s
        end do
    end if

    wsum = sum(wr(1:nr))
    do i = 1,nr
        dr_global(i) = (rmax-rmin)*wr(i)/wsum
    end do

    rface_global(0) = rmin
    do i = 1,nr
        rface_global(i) = rface_global(i-1) + dr_global(i)
    end do

    do i = 1,nr
        rcell_global(i) = 0.5*(rface_global(i-1) + rface_global(i))
    end do

    do j = 1,na
        da_global(j) = da0
    end do

    beta_z = 4.0
    if (nz == 1) then
        wz(1) = 1.0
    else
        do k = 1,nz
            s = real(k-1)/real(nz-1)
            wz(k) = 1.0 + beta_z*(1.0 - (2.0*s - 1.0)**2)
        end do
    end if

    wsum = sum(wz(1:nz))
    do k = 1,nz
        dz_global(k) = lz*wz(k)/wsum
    end do

    zface_global(0) = 0.0
    do k = 1,nz
        zface_global(k) = zface_global(k-1) + dz_global(k)
    end do

    do k = 1,nz
        zcell_global(k) = 0.5*(zface_global(k-1) + zface_global(k))
    end do

    allocate(dr(il_loc(1)-1:iu_loc(1)+1))
    allocate(da(il_loc(2)-1:iu_loc(2)+1))
    allocate(dz(il_loc(3)-1:iu_loc(3)+1))

    dr = 0.0
    da = 0.0
    dz = 0.0

    do i = il_loc(1),iu_loc(1)
        dr(i) = dr_global(i)
    end do
    do j = il_loc(2),iu_loc(2)
        da(j) = da_global(j)
    end do
    do k = il_loc(3),iu_loc(3)
        dz(k) = dz_global(k)
    end do

    call exchange_ghost_width(cart_comm,nbr_r_lo,nbr_r_hi,101,102,dr,il_loc(1),iu_loc(1))
    call exchange_ghost_width(cart_comm,nbr_a_lo,nbr_a_hi,201,202,da,il_loc(2),iu_loc(2))
    call exchange_ghost_width(cart_comm,nbr_z_lo,nbr_z_hi,301,302,dz,il_loc(3),iu_loc(3))

    rface_lo = rface_global(il_loc(1)-1)

    allocate(phi1d(1:nloc))
    allocate(phi_exact(1:nloc))
    allocate(rho1d(1:nloc))
    allocate(RHS(1:nloc))
    allocate(A_values(1:7*nloc))

    phi1d = 0.0
    phi_exact = 0.0
    rho1d = 0.0
    RHS = 0.0
    A_values = 0.0

    do_init = .false.
    do_updateA = .false.
    do_finalize = .false.
    solver = 0_8
    grid = 0_8
    stencil = 0_8
    A = 0_8
    b = 0_8
    x = 0_8

    kappa = j1_zero_1/rmax
    mu = pi/lz

    l = 1
    do k = il_loc(3),iu_loc(3)
    do j = il_loc(2),iu_loc(2)
    do i = il_loc(1),iu_loc(1)
        r = rcell_global(i)
        alpha = (real(j)-0.5)*da0
        z = zcell_global(k)

        phi_ex = bessel_j1(kappa*r)*cos(alpha)*sin(mu*z)
        rho_ex = eps0*(kappa*kappa + mu*mu)*phi_ex

        phi_exact(l) = phi_ex
        rho1d(l) = rho_ex
        l = l + 1
    end do
    end do
    end do

    call HYPRE_Initialize(ierr_h)

    call sub_D04_hypre_3Draz_nonuniform_A_mpi(il_loc,iu_loc,rface_lo,eps0,dr,da,dz, &
        periodic,has_neighbor,bc_type,bc_value,A_values,rho1d,RHS)

    do_init = .true.
    do_updateA = .false.
    do_finalize = .false.
    call sub_D04_hypre_3Draz_nonuniform(fcomm,il_loc,iu_loc,phi1d,RHS, &
        tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
        solver,grid,stencil,A,b,x)

    do_init = .false.
    do_updateA = .false.
    do_finalize = .true.
    call sub_D04_hypre_3Draz_nonuniform(fcomm,il_loc,iu_loc,phi1d,RHS, &
        tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
        solver,grid,stencil,A,b,x)

    call HYPRE_Finalize(ierr_h)

    ! ------------------------------------------------------------
    ! Global volume-weighted error norms.
    ! ------------------------------------------------------------
    err_linf_loc = 0.0
    err_l2_loc = 0.0
    ref_l2_loc = 0.0

    l = 1
    do k = il_loc(3),iu_loc(3)
    do j = il_loc(2),iu_loc(2)
    do i = il_loc(1),iu_loc(1)
        diff = phi1d(l)-phi_exact(l)
        vol = rcell_global(i)*dr_global(i)*da_global(j)*dz_global(k)

        err_linf_loc = max(err_linf_loc,abs(diff))
        err_l2_loc = err_l2_loc + diff*diff*vol
        ref_l2_loc = ref_l2_loc + phi_exact(l)*phi_exact(l)*vol

        l = l + 1
    end do
    end do
    end do

    call mpi_reduce(err_linf_loc,err_linf,1,MPI_DOUBLE_PRECISION,MPI_MAX,0,cart_comm,ierr)
    call mpi_reduce(err_l2_loc,err_l2,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,cart_comm,ierr)
    call mpi_reduce(ref_l2_loc,ref_l2,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,cart_comm,ierr)

    if (mpi_i == 0) then
        err_l2 = sqrt(err_l2/max(ref_l2,tiny(1.0)))
        write(*,*) '========================================='
        write(*,*) 'D04 multi-MPI analytic test (r,a,z split)'
        write(*,*) 'phi = J1(kappa*r)*cos(alpha)*sin(pi*z/Lz)'
        write(*,*) 'radial grid : nonuniform'
        write(*,*) 'axial  grid : nonuniform'
        write(*,*) 'MPI ranks      = ',mpi_n
        write(*,*) 'MPI dims(r,a,z)= ',dims
        write(*,*) 'beta_r = ',beta_r
        write(*,*) 'beta_z = ',beta_z
        write(*,*) 'kappa = ',kappa
        write(*,*) 'nr,na,nz = ',nr,na,nz
        write(*,*) 'min(dr), max(dr) = ',minval(dr_global),maxval(dr_global)
        write(*,*) 'min(dz), max(dz) = ',minval(dz_global),maxval(dz_global)
        write(*,*) 'L_inf error     = ',err_linf
        write(*,*) 'relative L2 err = ',err_l2
        write(*,*) '========================================='
        do p = 0,mpi_n-1
            call mpi_cart_coords(cart_comm,p,3,coords_p,ierr)
            call partition_1d(nr,dims(1),coords_p(1),il_tmp(1),iu_tmp(1))
            call partition_1d(na,dims(2),coords_p(2),il_tmp(2),iu_tmp(2))
            call partition_1d(nz,dims(3),coords_p(3),il_tmp(3),iu_tmp(3))
            write(*,'(A,I4,A,3I4,A,6I6)') 'rank ',p,' coords=',coords_p, &
                ' owns(i1,i2,j1,j2,k1,k2)=', &
                il_tmp(1),iu_tmp(1),il_tmp(2),iu_tmp(2),il_tmp(3),iu_tmp(3)
        end do
    end if

    if (mpi_i == 0) then
        allocate(phi_all(1:nr,1:na,1:nz))
        allocate(phi_exact_all(1:nr,1:na,1:nz))
        phi_all = 0.0
        phi_exact_all = 0.0

        call unpack_block(phi1d,phi_all,il_loc,iu_loc)
        call unpack_block(phi_exact,phi_exact_all,il_loc,iu_loc)

        do p = 1,mpi_n-1
            call mpi_recv(header,6,MPI_INTEGER,p,401,cart_comm,status,ierr)
            nbuf_recv = (header(2)-header(1)+1)*(header(4)-header(3)+1)*(header(6)-header(5)+1)
            allocate(phi_buf(1:nbuf_recv))
            allocate(phi_exact_buf(1:nbuf_recv))
            call mpi_recv(phi_buf,nbuf_recv,MPI_DOUBLE_PRECISION,p,402,cart_comm,status,ierr)
            call mpi_recv(phi_exact_buf,nbuf_recv,MPI_DOUBLE_PRECISION,p,403,cart_comm,status,ierr)
            il_tmp = (/header(1),header(3),header(5)/)
            iu_tmp = (/header(2),header(4),header(6)/)
            call unpack_block(phi_buf,phi_all,il_tmp,iu_tmp)
            call unpack_block(phi_exact_buf,phi_exact_all,il_tmp,iu_tmp)
            deallocate(phi_buf,phi_exact_buf)
        end do

        open(unit=1001,file='phi_compare.dat',status='replace')
        write(1001,*) '# i j k r alpha z phi_num phi_exact abs_error'

        do k = 1,nz
        do j = 1,na
        do i = 1,nr
            r = rcell_global(i)
            alpha = (real(j)-0.5)*da0
            z = zcell_global(k)
            write(1001,'(3I6,1X,6ES24.14)') i,j,k,r,alpha,z,phi_all(i,j,k), &
                phi_exact_all(i,j,k),abs(phi_all(i,j,k)-phi_exact_all(i,j,k))
        end do
        end do
        end do
        close(1001)
    else
        header = (/il_loc(1),iu_loc(1),il_loc(2),iu_loc(2),il_loc(3),iu_loc(3)/)
        call mpi_send(header,6,MPI_INTEGER,0,401,cart_comm,ierr)
        call mpi_send(phi1d,nloc,MPI_DOUBLE_PRECISION,0,402,cart_comm,ierr)
        call mpi_send(phi_exact,nloc,MPI_DOUBLE_PRECISION,0,403,cart_comm,ierr)
    end if

    if (allocated(phi_all)) deallocate(phi_all)
    if (allocated(phi_exact_all)) deallocate(phi_exact_all)

    deallocate(dr_global,da_global,dz_global)
    deallocate(wr,wz)
    deallocate(rcell_global,zcell_global)
    deallocate(rface_global,zface_global)
    deallocate(dr,da,dz)
    deallocate(phi1d,phi_exact,rho1d,RHS,A_values)

    call mpi_finalize(ierr)

contains

    subroutine partition_1d(n_global,n_parts,coord,ilo,ihi)
        implicit none
        integer :: n_global,n_parts,coord,ilo,ihi
        integer :: base,rem_1d,n_local

        base = n_global/n_parts
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

    subroutine exchange_ghost_width(comm,left_rank,right_rank,tag_l,tag_r,arr,ilo,ihi)
        implicit none
        integer :: comm,left_rank,right_rank,tag_l,tag_r,ilo,ihi
        integer :: status_loc(MPI_STATUS_SIZE)
        real :: arr(ilo-1:ihi+1)

        call mpi_sendrecv(arr(ilo),1,MPI_DOUBLE_PRECISION,left_rank,tag_l, &
            arr(ihi+1),1,MPI_DOUBLE_PRECISION,right_rank,tag_l, &
            comm,status_loc,ierr)

        call mpi_sendrecv(arr(ihi),1,MPI_DOUBLE_PRECISION,right_rank,tag_r, &
            arr(ilo-1),1,MPI_DOUBLE_PRECISION,left_rank,tag_r, &
            comm,status_loc,ierr)
    end subroutine exchange_ghost_width

    subroutine unpack_block(buf,field,il_box,iu_box)
        implicit none
        real :: buf(:)
        real :: field(:,:,:)
        integer :: il_box(1:3),iu_box(1:3)
        integer :: ii,jj,kk,ll

        ll = 1
        do kk = il_box(3),iu_box(3)
        do jj = il_box(2),iu_box(2)
        do ii = il_box(1),iu_box(1)
            field(ii,jj,kk) = buf(ll)
            ll = ll + 1
        end do
        end do
        end do
    end subroutine unpack_block

end program main_D04_test_multi_mpi_raz
