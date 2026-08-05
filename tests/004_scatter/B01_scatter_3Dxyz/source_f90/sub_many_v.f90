subroutine sub_many_v(il, iu, w, d, outfile_den, outfile_par)

    implicit none

    integer, dimension(1:3), intent(in) :: il, iu
    real, intent(in) :: w
    integer, intent(in) :: d
    character(len=*), intent(in) :: outfile_den
    character(len=*), intent(in) :: outfile_par

    integer :: np_max, np
    real, allocatable, dimension(:,:) :: par
    real, allocatable, dimension(:,:,:) :: den

    integer :: i, j, k, p
    integer :: unit_den, unit_par
    real :: total, expected_total

    integer :: z_box, z_h, z_cross
    real :: v_box, v_h, v_cross

    np_max = 1000
    allocate(par(1:6,1:np_max))
    par = 0.0
    np = 0

    z_box   = 3
    z_h     = 5
    z_cross = 7
    v_box   = 1.0
    v_h     = 2.0
    v_cross = 3.0

    !=========================================================
    ! Layer 1: hollow square frame on z = 3, velocity = v_box
    !=========================================================
    do i = 3, 7
        call add_particle_v(i, 3, z_box, v_box, d, np, np_max, par)
        call add_particle_v(i, 7, z_box, v_box, d, np, np_max, par)
    end do
    do j = 4, 6
        call add_particle_v(3, j, z_box, v_box, d, np, np_max, par)
        call add_particle_v(7, j, z_box, v_box, d, np, np_max, par)
    end do

    !=========================================================
    ! Layer 2: H shape on z = 5, velocity = v_h
    !=========================================================
    do j = 3, 7
        call add_particle_v(3, j, z_h, v_h, d, np, np_max, par)
        call add_particle_v(7, j, z_h, v_h, d, np, np_max, par)
    end do
    do i = 3, 7
        call add_particle_v(i, 5, z_h, v_h, d, np, np_max, par)
    end do

    !=========================================================
    ! Layer 3: cross shape on z = 7, velocity = v_cross
    !=========================================================
    do i = 3, 7
        call add_particle_v(i, 5, z_cross, v_cross, d, np, np_max, par)
    end do
    do j = 3, 7
        call add_particle_v(5, j, z_cross, v_cross, d, np, np_max, par)
    end do

    allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    den = 0.0

    call sub_B01_scatter_3Dxyz_v(il, iu, den, np, par, w, d)

    total = sum(den)
    expected_total = w * sum(par(d,1:np))

    print *, '  number of particles = ', np
    print *, '  component d         = ', d
    print *, '  particle weight     = ', w
    print *, '  total sum of den    = ', total
    print *, '  expected total      = ', expected_total
    print *, '  suggested XY slices:'
    print *, '    k = ', z_box,   '  (box frame,  v = ', v_box,   ')'
    print *, '    k = ', z_h,     '  (H shape,    v = ', v_h,     ')'
    print *, '    k = ', z_cross, '  (cross,      v = ', v_cross, ')'

    unit_par = 501
    open(unit=unit_par, file=trim(outfile_par), status='replace', action='write')
    write(unit_par, '(A)') '# p   xp   yp   zp   vd'
    do p = 1, np
        write(unit_par,'(I8,3(1X,F12.6),1X,F12.6)') &
            p, par(1,p), par(2,p), par(3,p), par(d,p)
    end do
    close(unit_par)

    unit_den = 502
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

    subroutine add_particle_v(ic, jc, kc, v, d, np, np_max, par)
        implicit none
        integer, intent(in) :: ic, jc, kc, np_max, d
        real, intent(in) :: v
        integer, intent(inout) :: np
        real, dimension(1:6,1:np_max), intent(inout) :: par

        np = np + 1
        if (np > np_max) then
            print *, 'Error: particle array capacity exceeded.'
            stop
        end if

        par(1,np) = real(ic) + 0.5
        par(2,np) = real(jc) + 0.5
        par(3,np) = real(kc) + 0.5
        par(d,np) = v
    end subroutine add_particle_v

end subroutine sub_many_v
