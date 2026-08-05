subroutine sub_single_v(il, iu, xp, yp, zp, vp, w, d, outfile)

    implicit none

    integer, dimension(1:3), intent(in) :: il, iu
    real, intent(in) :: xp, yp, zp, vp, w
    integer, intent(in) :: d
    character(len=*), intent(in) :: outfile

    integer :: np
    real, allocatable, dimension(:,:,:) :: den
    real, allocatable, dimension(:,:) :: par

    integer :: i0, j0, k0
    integer :: i, j, k
    integer :: unit_out

    allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    den = 0.0

    np = 1
    allocate(par(1:6,1:np))
    par = 0.0

    par(1,1) = xp
    par(2,1) = yp
    par(3,1) = zp
    par(d,1) = vp

    call sub_B01_scatter_3Dxyz_v(il, iu, den, np, par, w, d)

    i0 = floor(xp)
    j0 = floor(yp)
    k0 = floor(zp)

    print *, '  particle position = ', xp, yp, zp
    print *, '  component d       = ', d
    print *, '  par(d,1)          = ', vp
    print *, '  particle weight   = ', w
    print *, '  nonzero stencil values:'
    print '(A,I4,A,I4,A,I4,A,ES16.8)', &
        '    den(',i0  ,',',j0  ,',',k0  ,') = ', den(i0  ,j0  ,k0  )
    print '(A,I4,A,I4,A,I4,A,ES16.8)', &
        '    den(',i0+1,',',j0  ,',',k0  ,') = ', den(i0+1,j0  ,k0  )
    print '(A,I4,A,I4,A,I4,A,ES16.8)', &
        '    den(',i0  ,',',j0+1,',',k0  ,') = ', den(i0  ,j0+1,k0  )
    print '(A,I4,A,I4,A,I4,A,ES16.8)', &
        '    den(',i0  ,',',j0  ,',',k0+1,') = ', den(i0  ,j0  ,k0+1)
    print '(A,I4,A,I4,A,I4,A,ES16.8)', &
        '    den(',i0+1,',',j0+1,',',k0  ,') = ', den(i0+1,j0+1,k0  )
    print '(A,I4,A,I4,A,I4,A,ES16.8)', &
        '    den(',i0  ,',',j0+1,',',k0+1,') = ', den(i0  ,j0+1,k0+1)
    print '(A,I4,A,I4,A,I4,A,ES16.8)', &
        '    den(',i0+1,',',j0  ,',',k0+1,') = ', den(i0+1,j0  ,k0+1)
    print '(A,I4,A,I4,A,I4,A,ES16.8)', &
        '    den(',i0+1,',',j0+1,',',k0+1,') = ', den(i0+1,j0+1,k0+1)
    print *, '  total sum of den = ', sum(den)
    print *, '  expected total   = ', vp * w

    unit_out = 401
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

    deallocate(den, par)

end subroutine sub_single_v
