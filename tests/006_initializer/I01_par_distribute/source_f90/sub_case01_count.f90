! Verify total particle count = product(ncell) * product(nppc).
! Allocates np+1 slots and fills slots 1..np with sentinel; after the call
! slot np+1 must still be sentinel (routine did not overshoot) and slots
! 1..np must be filled (routine did not undershoot).
subroutine sub_case01_count()
    implicit none

    integer, dimension(1:3) :: il, iu, nppc
    integer :: np
    real, allocatable :: par(:,:)
    real, dimension(1:3) :: vt, vd
    logical :: pass
    real, parameter :: sentinel = -1.0e38

    vt = 0.0; vd = 0.0

    ! A: 3x3x3 cells, 2x3x4 ppc = 216 particles
    il = (/1,1,1/); iu = (/3,3,3/); nppc = (/2,3,4/)
    np = product(iu-il+1) * product(nppc)
    allocate(par(1:6, 1:np+1))
    par = sentinel
    call sub_I01_par_distribute_equilibrium(par(:,1:np), nppc, il, iu, vt, vd)
    pass = all(par(:,np) > sentinel*0.5) .and. all(par(:,np+1) < sentinel*0.5)
    if (pass) then
        write(*,'("  A: 3x3x3 * 2x3x4 =",i5," particles  PASS")') np
    else
        write(*,'("  A: 3x3x3 * 2x3x4 =",i5," particles  FAIL")') np
    end if
    deallocate(par)

    ! B: 1x1x1 cell, 1x1x1 ppc = 1 particle
    il = (/5,3,2/); iu = (/5,3,2/); nppc = (/1,1,1/)
    np = 1
    allocate(par(1:6, 1:np+1))
    par = sentinel
    call sub_I01_par_distribute_equilibrium(par(:,1:np), nppc, il, iu, vt, vd)
    pass = all(par(:,np) > sentinel*0.5) .and. all(par(:,np+1) < sentinel*0.5)
    if (pass) then
        write(*,'("  B: 1x1x1 * 1x1x1 =",i5," particle   PASS")') np
    else
        write(*,'("  B: 1x1x1 * 1x1x1 =",i5," particle   FAIL")') np
    end if
    deallocate(par)

    ! C: 5x4x3 cells, 3x2x4 ppc = 720 particles
    il = (/1,1,1/); iu = (/5,4,3/); nppc = (/3,2,4/)
    np = product(iu-il+1) * product(nppc)
    allocate(par(1:6, 1:np+1))
    par = sentinel
    call sub_I01_par_distribute_equilibrium(par(:,1:np), nppc, il, iu, vt, vd)
    pass = all(par(:,np) > sentinel*0.5) .and. all(par(:,np+1) < sentinel*0.5)
    if (pass) then
        write(*,'("  C: 5x4x3 * 3x2x4 =",i5," particles  PASS")') np
    else
        write(*,'("  C: 5x4x3 * 3x2x4 =",i5," particles  FAIL")') np
    end if
    deallocate(par)

end subroutine sub_case01_count
