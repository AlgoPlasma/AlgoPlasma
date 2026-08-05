subroutine sub_multi(il, iu, np, par, w, outfile)

    implicit none

    integer, dimension(1:3), intent(in) :: il, iu
    integer, intent(in) :: np
    real, dimension(1:3,1:np), intent(in) :: par
    real, intent(in) :: w
    character(len=*), intent(in) :: outfile

    real, allocatable, dimension(:,:,:) :: den
    integer :: i, j, k
    integer :: p
    integer :: unit_out
    real :: total
    real :: expected_total

    allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    den = 0.0

    call sub_B01_scatter_3Dxyz(il, iu, den, np, par, w)

    total = sum(den)
    expected_total = real(np) * w

    print *, '  number of particles = ', np
    print *, '  particle weight     = ', w
    print *, '  particle positions:'
    do p = 1, np
        print *, '    p = ', p, '  x,y,z = ', par(1,p), par(2,p), par(3,p)
    end do
    print *, '  nonzero grid nodes:'
    do k = il(3)-1, iu(3)+1
        do j = il(2)-1, iu(2)+1
            do i = il(1)-1, iu(1)+1
                if (abs(den(i,j,k)) > 1.0d-12) then
                    print '(A,I4,A,I4,A,I4,A,ES20.10)', &
                        'den(', i, ',', j, ',', k, ') = ', den(i,j,k)
                end if
            end do
        end do
    end do
    print *, '  total sum of den = ', total
    print *, '  expected total   = ', expected_total

    unit_out = 102
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

    deallocate(den)

end subroutine sub_multi
