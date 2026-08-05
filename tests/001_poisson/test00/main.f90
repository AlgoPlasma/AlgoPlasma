program main

    use mpi
    use mod_D01_hypre_3Dxyz_bc
    implicit none

    ! mpi_i: The ith MPI rank.
    ! mpi_n: The MPI size.
    integer :: ierr,mpi_i,mpi_n

    ! Local,global lower and upper indicies.
    integer,dimension(1:3) :: il,iu,il0,iu0

    ! Boundary condition flag in x,z small and big.
    ! 0: inner.
    ! 1: Dirichlet.
    ! 2: Numeann.
    ! y is set to be periodic.
    integer :: bc(1:4)

    ! Potential and charge density array.
    real,dimension(:),allocatable :: phi1d
    real,dimension(:),allocatable :: rho1d

    integer :: n,i,j,k,l
    real :: tolerance
    real :: xc,zc,sigma

    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
    call mpi_comm_size(mpi_comm_world,mpi_n,ierr)

    if (mpi_n /= 4) then
        if (mpi_i == 0) then
            write(*,*) 'ERROR: this test is intended for 4 MPI ranks only.'
        end if
        call mpi_finalize(ierr)
        stop
    end if

    if (mpi_i==0) then
        il(1:3) = (/ 9, 1, 1/)
        iu(1:3) = (/24, 8,16/)
        bc(1:4) = (/2,2,1,0/)
    else if (mpi_i==1) then
        il(1:3) = (/ 1, 1,17/)
        iu(1:3) = (/ 8, 8,32/)
        bc(1:4) = (/1,0,1,1/)
    else if (mpi_i==2) then
        il(1:3) = (/ 9, 1,17/)
        iu(1:3) = (/24, 8,32/)
        bc(1:4) = (/0,0,0,1/)
    else if (mpi_i==3) then
        il(1:3) = (/25, 1,17/)
        iu(1:3) = (/32, 8,32/)
        bc(1:4) = (/0,1,1,1/)
    end if

    il0(1:3) = (/ 1, 1, 1/)
    iu0(1:3) = (/32, 8,32/)

    n = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)

    allocate(phi1d(1:n))
    allocate(rho1d(1:n))
    phi1d = 0.0
    rho1d = 0.0

    if (mpi_i==0) then
        l = 1
        do k = il(3), iu(3)
        do j = il(2), iu(2)
        do i = il(1), iu(1)
            if (k==il(3)) rho1d(l) = 1.0  !zmin =0.5v
            l = l + 1
        end do
        end do
        end do
    end if


    tolerance = 1.0e-6
!    xc = 16.5
!    zc = 16.5
!    sigma = 4.0

!    l = 1
!    do k = il(3), iu(3)
!    do j = il(2), iu(2)
!    do i = il(1), iu(1)
!        rho1d(l) = exp(-((real(i)-xc)**2 + (real(k)-zc)**2)/(2.0*sigma**2))
!        l = l + 1
!    end do
!    end do
!    end do

    call sub_D01_hypre_3Dxyz_interface(n,phi1d,rho1d,il,iu,il0,iu0,tolerance,bc)

    block
    real,dimension(:,:,:),allocatable :: phi0,phi
    integer :: ni,nj,nk

    allocate(phi (il0(1):iu0(1),il0(2):iu0(2),il0(3):iu0(3)))
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

    deallocate(phi1d, rho1d)
    call mpi_finalize(ierr)

end
