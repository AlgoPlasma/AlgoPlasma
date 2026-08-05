subroutine sub_many(il, iu, w, outfile_den, outfile_par)

    implicit none

    integer, dimension(1:3), intent(in) :: il, iu
    real, intent(in) :: w
    character(len=*), intent(in) :: outfile_den
    character(len=*), intent(in) :: outfile_par

    integer :: np_max, np
    real, allocatable, dimension(:,:) :: par
    real, allocatable, dimension(:,:,:) :: den

    integer :: i, j, k, p
    integer :: unit_den, unit_par
    real :: total, expected_total

    integer :: z_box, z_h, z_cross

    np_max = 1000
    allocate(par(1:3,1:np_max))
    par = 0.0
    np = 0

    !---------------------------------
    ! layer positions
    !---------------------------------
    z_box   = 3
    z_h     = 5
    z_cross = 7

    !=========================================================
    ! Layer 1: hollow square frame on z = 3
    ! x,y in [3,7]
    !=========================================================
    do i = 3, 7
        call add_particle(i, 3, z_box,   np, np_max, par)
        call add_particle(i, 7, z_box,   np, np_max, par)
    end do
    do j = 4, 6
        call add_particle(3, j, z_box,   np, np_max, par)
        call add_particle(7, j, z_box,   np, np_max, par)
    end do

    !=========================================================
    ! Layer 2: H shape on z = 5
    !=========================================================
    do j = 3, 7
        call add_particle(3, j, z_h, np, np_max, par)
        call add_particle(7, j, z_h, np, np_max, par)
    end do
    do i = 3, 7
        call add_particle(i, 5, z_h, np, np_max, par)
    end do

    !=========================================================
    ! Layer 3: cross shape on z = 7
    !=========================================================
    do i = 3, 7
        call add_particle(i, 5, z_cross, np, np_max, par)
    end do
    do j = 3, 7
        call add_particle(5, j, z_cross, np, np_max, par)
    end do

    allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    den = 0.0

    call sub_B01_scatter_3Dxyz(il, iu, den, np, par, w)

    total = sum(den)
    expected_total = real(np) * w

    print *, '  number of particles = ', np
    print *, '  particle weight     = ', w
    print *, '  total sum of den    = ', total
    print *, '  expected total      = ', expected_total
    print *, '  suggested XY slices:'
    print *, '    k = ', z_box
    print *, '    k = ', z_h
    print *, '    k = ', z_cross

    unit_par = 301
    open(unit=unit_par, file=trim(outfile_par), status='replace', action='write')
    write(unit_par, '(A)') '# p   xp   yp   zp'
    do p = 1, np
        write(unit_par,'(I8,3(1X,F12.6))') p, par(1,p), par(2,p), par(3,p)
    end do
    close(unit_par)

    unit_den = 302
    open(unit=unit_den, file=trim(outfile_den), status='replace', action='write')
    write(unit_den, '(A)') '# i  j  k  den(i,j,k)'
    do k = il(3)-1, iu(3)+1
        do j = il(2)-1, iu(2)+1
            do i = il(1)-1, iu(1)+1
                write(unit_den,'(3I8,1X,ES20.10)') i, j, k, den(i,j,k)
            end do
        end do
    end do
    close(unit_den)

    deallocate(par)
    deallocate(den)

contains

    subroutine add_particle(ic, jc, kc, np, np_max, par)
        implicit none
        integer, intent(in) :: ic, jc, kc, np_max
        integer, intent(inout) :: np
        real, dimension(1:3,1:np_max), intent(inout) :: par

        np = np + 1
        if (np > np_max) then
            print *, 'Error: particle array capacity exceeded.'
            stop
        end if

        par(1,np) = real(ic) + 0.5
        par(2,np) = real(jc) + 0.5
        par(3,np) = real(kc) + 0.5
    end subroutine add_particle

end subroutine sub_many
