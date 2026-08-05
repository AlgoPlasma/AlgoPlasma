subroutine sub_single(il, iu, xp, yp, zp, w, outfile)

    implicit none

    integer, dimension(1:3), intent(in) :: il, iu
    real, intent(in) :: xp, yp, zp
    real, intent(in) :: w
    character(len=*), intent(in) :: outfile

    integer :: np
    real, allocatable, dimension(:,:,:) :: den
    real, allocatable, dimension(:,:) :: par

    integer :: i, j, k
    real :: total
    integer :: unit_out

    !---------------------------------
    ! 1. allocate arrays
    !---------------------------------
    allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    den = 0.0

    np = 1
    allocate(par(1:6,1:np))
    par = 0.0

    !---------------------------------
    ! 2. set particle position
    !---------------------------------
    par(1,1) = xp
    par(2,1) = yp
    par(3,1) = zp

    !---------------------------------
    ! 3. call scatter
    !---------------------------------
    call sub_B01_scatter_3Dxyz(il, iu, den, np, par, w)

    !---------------------------------
    ! 4. print basic information
    !---------------------------------
    print *, '  particle position = ', xp, yp, zp
    print *, '  particle weight   = ', w
    print *, '  nonzero stencil values:'
    print *, 'den(2,3,4) = ', den(2,3,4)
    print *, 'den(3,3,4) = ', den(3,3,4)
    print *, 'den(2,4,4) = ', den(2,4,4)
    print *, 'den(2,3,5) = ', den(2,3,5)
    print *, 'den(3,4,4) = ', den(3,4,4)
    print *, 'den(3,3,5) = ', den(3,3,5)
    print *, 'den(2,4,5) = ', den(2,4,5)
    print *, 'den(3,4,5) = ', den(3,4,5)

    total = sum(den)
    print *, '  total sum of den = ', total

    !---------------------------------
    ! 5. write full grid to file
    !---------------------------------
    unit_out = 101
    open(unit=unit_out, file=trim(outfile), status='replace', action='write')

    write(unit_out, '(A)') '# i  j  k  den(i,j,k)'

    do k = il(3)-1, iu(3)+1
        do j = il(2)-1, iu(2)+1
            do i = il(1)-1, iu(1)+1
                write(unit_out,'(3I8,1X,ES20.10)') i, j, k, den(i,j,k)
            end do
        end do
    end do

    close(unit_out)

    !---------------------------------
    ! 6. release memory
    !---------------------------------
    deallocate(den, par)

end subroutine sub_single
