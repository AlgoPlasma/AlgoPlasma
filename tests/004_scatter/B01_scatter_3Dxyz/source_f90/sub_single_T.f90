! Analytical unit tests for sub_B01_scatter_3Dxyz_T.
! Requires d in 4..6 (velocity components) to avoid conflicting with
! position components par(1:3,p) used for nearest-cell assignment.
subroutine sub_single_T(il, iu, d)

    implicit none

    integer, dimension(1:3), intent(in) :: il, iu
    integer, intent(in) :: d

    integer :: np, p
    real, allocatable :: T(:,:,:), par(:,:)
    real :: v, expected_T
    real, parameter :: tol = 1.0e-5

    ! Particle at (4.5, 4.5, 4.5) → nearest-cell (5, 5, 5)
    ! Particle at (6.5, 6.5, 6.5) → nearest-cell (7, 7, 7)

    print *, '  d = ', d

    !------------------------------------------------------
    ! Test A: single particle → T = 0 (no variance)
    !------------------------------------------------------
    np = 1
    allocate(par(1:6,1:np));                                  par = 0.0
    allocate(T(il(1):iu(1),il(2):iu(2),il(3):iu(3)));        T = 0.0

    par(1,1) = 4.5;  par(2,1) = 4.5;  par(3,1) = 4.5
    par(d,1) = 3.0

    call sub_B01_scatter_3Dxyz_T(il, iu, T, np, par, d)

    write(*,'(A,F10.6,A,F10.6)') &
        '  Test A: expected T(5,5,5) = 0.000000  got ', T(5,5,5)
    if (abs(T(5,5,5)) < tol) then
        print *, '    PASS'
    else
        print *, '    FAIL'
    end if
    deallocate(par, T)

    !------------------------------------------------------
    ! Test B: N particles with same velocity → T = 0
    !------------------------------------------------------
    np = 5;  v = 2.0
    allocate(par(1:6,1:np));                                  par = 0.0
    allocate(T(il(1):iu(1),il(2):iu(2),il(3):iu(3)));        T = 0.0

    do p = 1, np
        par(1,p) = 4.5;  par(2,p) = 4.5;  par(3,p) = 4.5
        par(d,p) = v
    end do

    call sub_B01_scatter_3Dxyz_T(il, iu, T, np, par, d)

    write(*,'(A,F10.6,A,F10.6)') &
        '  Test B: expected T(5,5,5) = 0.000000  got ', T(5,5,5)
    if (abs(T(5,5,5)) < tol) then
        print *, '    PASS'
    else
        print *, '    FAIL'
    end if
    deallocate(par, T)

    !------------------------------------------------------
    ! Test C: 2 particles with ±v → T = v^2
    !------------------------------------------------------
    np = 2;  v = 3.0
    allocate(par(1:6,1:np));                                  par = 0.0
    allocate(T(il(1):iu(1),il(2):iu(2),il(3):iu(3)));        T = 0.0

    par(1,1) = 4.5;  par(2,1) = 4.5;  par(3,1) = 4.5;  par(d,1) = +v
    par(1,2) = 4.5;  par(2,2) = 4.5;  par(3,2) = 4.5;  par(d,2) = -v
    expected_T = v**2

    call sub_B01_scatter_3Dxyz_T(il, iu, T, np, par, d)

    write(*,'(A,F10.6,A,F10.6)') &
        '  Test C: expected T(5,5,5) = ', expected_T, '  got ', T(5,5,5)
    if (abs(T(5,5,5) - expected_T) < tol) then
        print *, '    PASS'
    else
        print *, '    FAIL'
    end if
    deallocate(par, T)

    !------------------------------------------------------
    ! Test D: 4 particles with [1,3,1,3] → mean=2, T=1.0
    !------------------------------------------------------
    np = 4
    allocate(par(1:6,1:np));                                  par = 0.0
    allocate(T(il(1):iu(1),il(2):iu(2),il(3):iu(3)));        T = 0.0

    do p = 1, np
        par(1,p) = 4.5;  par(2,p) = 4.5;  par(3,p) = 4.5
    end do
    par(d,1) = 1.0;  par(d,2) = 3.0;  par(d,3) = 1.0;  par(d,4) = 3.0
    expected_T = 1.0

    call sub_B01_scatter_3Dxyz_T(il, iu, T, np, par, d)

    write(*,'(A,F10.6,A,F10.6)') &
        '  Test D: expected T(5,5,5) = ', expected_T, '  got ', T(5,5,5)
    if (abs(T(5,5,5) - expected_T) < tol) then
        print *, '    PASS'
    else
        print *, '    FAIL'
    end if
    deallocate(par, T)

    !------------------------------------------------------
    ! Test E: two independent cells, variance must not mix
    !   cell (5,5,5): 2 particles ±2 → T = 4.0
    !   cell (7,7,7): 4 particles all 5.0 → T = 0.0
    !------------------------------------------------------
    np = 6
    allocate(par(1:6,1:np));                                  par = 0.0
    allocate(T(il(1):iu(1),il(2):iu(2),il(3):iu(3)));        T = 0.0

    par(1,1) = 4.5;  par(2,1) = 4.5;  par(3,1) = 4.5;  par(d,1) = +2.0
    par(1,2) = 4.5;  par(2,2) = 4.5;  par(3,2) = 4.5;  par(d,2) = -2.0
    par(1,3) = 6.5;  par(2,3) = 6.5;  par(3,3) = 6.5;  par(d,3) = 5.0
    par(1,4) = 6.5;  par(2,4) = 6.5;  par(3,4) = 6.5;  par(d,4) = 5.0
    par(1,5) = 6.5;  par(2,5) = 6.5;  par(3,5) = 6.5;  par(d,5) = 5.0
    par(1,6) = 6.5;  par(2,6) = 6.5;  par(3,6) = 6.5;  par(d,6) = 5.0

    call sub_B01_scatter_3Dxyz_T(il, iu, T, np, par, d)

    write(*,'(A,F10.6,A,F10.6)') &
        '  Test E: expected T(5,5,5) = 4.000000  got ', T(5,5,5)
    write(*,'(A,F10.6,A,F10.6)') &
        '         expected T(7,7,7) = 0.000000  got ', T(7,7,7)
    if (abs(T(5,5,5) - 4.0) < tol .and. abs(T(7,7,7)) < tol) then
        print *, '    PASS'
    else
        print *, '    FAIL'
    end if
    deallocate(par, T)

end subroutine sub_single_T
