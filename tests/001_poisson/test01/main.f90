program main

    use mpi
    use mod_D02_hypre_3Dxyz_bc
    implicit none
    include "HYPREf.h" 

    ! mpi_i: The ith MPI rank.
    ! mpi_n: The MPI size.
    integer :: ierr,ierr_h,mpi_i,mpi_n
    integer :: fcomm

    ! Local,global lower and upper indicies.
    integer,dimension(1:3) :: il,iu,il0,iu0

    ! Boundary condition flag in x,z small and big.
    ! 0: inner.
    ! 1: Dirichlet.
    ! 2: Numeann.
    ! 3: dielectric.
    ! 4: outflow.
    ! y is set to be periodic.
    integer :: bc(1:6)
    real :: phibc(1:6)
    integer,dimension(1:3) :: period

    ! Potential and charge density array.
    real,dimension(:),allocatable :: phi1d
    real,dimension(:),allocatable :: rho1d
    
    integer :: n,i,j,k,l
    real,dimension(:,:),allocatable :: sx1
    real,dimension(:,:),allocatable :: sx2
    real,dimension(:,:),allocatable :: sy1
    real,dimension(:,:),allocatable :: sy2
    real,dimension(:,:),allocatable :: sz1
    real,dimension(:,:),allocatable :: sz2

    real,dimension(:),allocatable :: A_values
    real :: phi_infty
    real,dimension(1:3) :: r0
    logical :: do_init,do_updateA,do_finalize
    integer(8) :: grid,stencil,A,b,x

    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
    call mpi_comm_size(mpi_comm_world,mpi_n,ierr)
    fcomm = MPI_COMM_WORLD  

    if (mpi_i==0) then
        il(1:3) = (/ 9, 1, 1/)
        iu(1:3) = (/24, 8,16/)
        bc(1:6) = (/3,3,0,0,1,0/)
        phibc(1:6) = (/0.0,0.0,0.0,0.0,0.5,0.0/) ! zmin = 0.5 V
        allocate(sx1(il(2)-1:iu(2),il(3)-1:iu(3)))
        allocate(sx2(il(2)-1:iu(2),il(3)-1:iu(3)))
        allocate(sy1(il(1)-1:iu(1),il(3)-1:iu(3)))
        allocate(sy2(il(1)-1:iu(1),il(3)-1:iu(3)))
        allocate(sz1(il(1)-1:iu(1),il(2)-1:iu(2)))
        allocate(sz2(il(1)-1:iu(1),il(2)-1:iu(2)))
        sx1 = +0.05
        sx2 = -0.05
        sy1 = 0.0
        sy2 = 0.0  
        sz1 = 0.0
        sz2 = 0.0

    else if (mpi_i==1) then
        il(1:3) = (/ 1, 1,17/)
        iu(1:3) = (/ 8, 8,32/)
        bc(1:6) = (/4,0,0,0,2,4/)
        phibc(1:6) = (/0.0,0.0,0.0,0.0,0.0,0.0/) ! xmin/zmax = outflow, zmin Neumann(E=0)
    else if (mpi_i==2) then
        il(1:3) = (/ 9, 1,17/)
        iu(1:3) = (/24, 8,32/)
        bc(1:6) = (/0,0,0,0,0,4/)
        phibc(1:6) = (/0.0,0.0,0.0,0.0,0.0,0.0/)
    else if (mpi_i==3) then
        il(1:3) = (/25, 1,17/)
        iu(1:3) = (/32, 8,32/)
        bc(1:6) = (/0,4,0,0,2,4/)
        phibc(1:6) = (/0.0,0.0,0.0,0.0,0.0,0.0/) ! xmax/zmax = outflow, zmin Neumann(E=0)
    end if

    period = (/0, 8, 0/)
    phi_infty = 0.0
    r0 = (/16.0, 4.0, 0.0/)

    il0(1:3) = (/1 , 1, 1/)
    iu0(1:3) = (/32, 8,32/)

    n = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)

    allocate(phi1d(1:n))
    allocate(rho1d(1:n))
    phi1d = 0.0
    rho1d = 0.0

    allocate(A_values(1:7*n)) !7-pt stencil    
    A_values = 0.0

    do_init = .false.
    do_updateA = .false.
    do_finalize = .false.
    grid = 0_8
    stencil = 0_8
    A = 0_8
    b = 0_8
    x = 0_8

    call HYPRE_Initialize(ierr_h) 
    call sub_D02_hypre_3Dxyz_bc_A(il,iu,A_values,rho1d,bc,phibc)
    call sub_D02_hypre_3Dxyz_bc_A_dielectric(il,iu,A_values,rho1d,bc,sx1,sx2,sy1,sy2,sz1,sz2)
    call sub_D02_hypre_3Dxyz_bc_A_outflow(il,iu,A_values,rho1d,bc,phi_infty,r0)
    do_init = .true.
    do_updateA = .false.
    do_finalize = .false.
    call sub_D02_hypre_3Dxyz_bc_fortran(fcomm, il, iu, phi1d, rho1d, &
        1.0e-6, A_values, period, do_init, do_updateA, do_finalize, &
        grid, stencil, A, b, x)

    do_init = .false.
    do_updateA = .false.
    do_finalize = .true.
    call sub_D02_hypre_3Dxyz_bc_fortran(fcomm, il, iu, phi1d, rho1d, &
        1.0e-6, A_values, period, do_init, do_updateA, do_finalize, &
        grid, stencil, A, b, x)

    block
    real,dimension(:,:,:),allocatable :: phi0,phi
    integer :: ni,nj,nk
    allocate( phi(il0(1):iu0(1),il0(2):iu0(2),il0(3):iu0(3)))
    allocate(phi0(il0(1):iu0(1),il0(2):iu0(2),il0(3):iu0(3)))
    phi  = 0.0
    phi0 = 0.0
    l = 1
    do k = il(3), iu(3)
    do j = il(2), iu(2)
    do i = il(1), iu(1)
        phi(i,j,k) = phi1d(l)
        l = l + 1
    end do
    end do
    end do
    ni = iu0(1)-il0(1)+1
    nj = iu0(2)-il0(2)+1
    nk = iu0(3)-il0(3)+1
    call mpi_allreduce(phi,phi0,ni*nj*nk,mpi_double,mpi_sum,mpi_comm_world,ierr)

    if (mpi_i==0) then
    open(unit=1000,file='phi.dat',status='replace')
    do k = il0(3), iu0(3)
    do j = il0(2), iu0(2)
    do i = il0(1), iu0(1)
        write(1000,*) phi0(i,j,k)
    end do
    end do
    end do
    close(1000)
    end if

    end block

    deallocate(phi1d, rho1d, A_values)
    call HYPRE_Finalize(ierr_h)
    call mpi_finalize(ierr)

end
