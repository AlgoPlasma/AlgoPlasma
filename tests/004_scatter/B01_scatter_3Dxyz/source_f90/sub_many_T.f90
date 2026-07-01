! Spatial pattern test for sub_B01_scatter_3Dxyz_T.
! Three 5x5 layers with analytically known temperature:
!   Layer k=4  (particles at kc=3): 4 particles/cell [1,3,1,3] → T = 1.0
!   Layer k=6  (particles at kc=5): 2 particles/cell [+2,-2]   → T = 4.0
!   Layer k=8  (particles at kc=7): 4 particles/cell [5,5,5,5] → T = 0.0
! Nearest-cell rule: i = floor(par(1,p)) + 1, so par(1)=ic+0.5 → cell ic+1.
! Requires d in 4..6 to avoid overwriting position components.
subroutine sub_many_T(il, iu, d, outfile_T, outfile_par)

    implicit none

    integer, dimension(1:3), intent(in) :: il, iu
    integer, intent(in) :: d
    character(len=*), intent(in) :: outfile_T
    character(len=*), intent(in) :: outfile_par

    integer :: np_max, np
    real, allocatable :: par(:,:), T(:,:,:)
    integer :: i, j, k, p
    integer :: unit_T, unit_par
    real :: sum_layer4, sum_layer6, sum_layer8

    np_max = 400
    allocate(par(1:6,1:np_max));  par = 0.0
    np = 0

    !=========================================================
    ! Layer k=4: cells (4..8, 4..8, 4), T expected = 1.0
    ! 4 particles per cell with par(d) = [1,3,1,3]
    !=========================================================
    do j = 3, 7
    do i = 3, 7
        call add_particle_T(i, j, 3, 1.0, d, np, np_max, par)
        call add_particle_T(i, j, 3, 3.0, d, np, np_max, par)
        call add_particle_T(i, j, 3, 1.0, d, np, np_max, par)
        call add_particle_T(i, j, 3, 3.0, d, np, np_max, par)
    end do
    end do

    !=========================================================
    ! Layer k=6: cells (4..8, 4..8, 6), T expected = 4.0
    ! 2 particles per cell with par(d) = [+2, -2]
    !=========================================================
    do j = 3, 7
    do i = 3, 7
        call add_particle_T(i, j, 5, +2.0, d, np, np_max, par)
        call add_particle_T(i, j, 5, -2.0, d, np, np_max, par)
    end do
    end do

    !=========================================================
    ! Layer k=8: cells (4..8, 4..8, 8), T expected = 0.0
    ! 4 particles per cell with par(d) = [5,5,5,5]
    !=========================================================
    do j = 3, 7
    do i = 3, 7
        call add_particle_T(i, j, 7, 5.0, d, np, np_max, par)
        call add_particle_T(i, j, 7, 5.0, d, np, np_max, par)
        call add_particle_T(i, j, 7, 5.0, d, np, np_max, par)
        call add_particle_T(i, j, 7, 5.0, d, np, np_max, par)
    end do
    end do

    allocate(T(il(1):iu(1),il(2):iu(2),il(3):iu(3)));  T = 0.0

    call sub_B01_scatter_3Dxyz_T(il, iu, T, np, par, d)

    sum_layer4 = 0.0
    sum_layer6 = 0.0
    sum_layer8 = 0.0
    do j = 4, 8
    do i = 4, 8
        sum_layer4 = sum_layer4 + T(i,j,4)
        sum_layer6 = sum_layer6 + T(i,j,6)
        sum_layer8 = sum_layer8 + T(i,j,8)
    end do
    end do

    print *, '  number of particles = ', np
    print *, '  component d         = ', d
    print *, '  Layer k=4  ([1,3,1,3], expected T per cell = 1.0):'
    write(*,'(A,F10.4,A)') '    sum T over 5x5 = ', sum_layer4, '  (expected 25.0)'
    write(*,'(A,F10.6,A)') '    T(4,4,4)       = ', T(4,4,4),  '  (expected 1.0)'
    print *, '  Layer k=6  ([+2,-2],   expected T per cell = 4.0):'
    write(*,'(A,F10.4,A)') '    sum T over 5x5 = ', sum_layer6, '  (expected 100.0)'
    write(*,'(A,F10.6,A)') '    T(4,4,6)       = ', T(4,4,6),  '  (expected 4.0)'
    print *, '  Layer k=8  ([5,5,5,5], expected T per cell = 0.0):'
    write(*,'(A,F10.4,A)') '    sum T over 5x5 = ', sum_layer8, '  (expected 0.0)'
    write(*,'(A,F10.6,A)') '    T(4,4,8)       = ', T(4,4,8),  '  (expected 0.0)'

    unit_par = 601
    open(unit=unit_par, file=trim(outfile_par), status='replace', action='write')
    write(unit_par, '(A)') '# p   xp   yp   zp   vd'
    do p = 1, np
        write(unit_par,'(I8,3(1X,F12.6),1X,F12.6)') &
            p, par(1,p), par(2,p), par(3,p), par(d,p)
    end do
    close(unit_par)

    unit_T = 602
    open(unit=unit_T, file=trim(outfile_T), status='replace', action='write')
    write(unit_T, '(A)') '# i  j  k  T(i,j,k)'
    do k = il(3), iu(3)
        do j = il(2), iu(2)
            do i = il(1), iu(1)
                write(unit_T,'(3I8,1X,ES20.10)') i, j, k, T(i,j,k)
            end do
        end do
    end do
    close(unit_T)

    deallocate(par, T)

contains

    subroutine add_particle_T(ic, jc, kc, v, d, np, np_max, par)
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
    end subroutine add_particle_T

end subroutine sub_many_T
