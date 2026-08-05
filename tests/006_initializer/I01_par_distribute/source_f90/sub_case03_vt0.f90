! When vt=0, every particle's velocity must equal vd exactly (not approximately).
! The Box-Muller result g is finite but multiplied by vt=0.0, giving 0.0 in
! floating point; adding vd yields exactly vd.
subroutine sub_case03_vt0()
    implicit none

    integer, dimension(1:3) :: il, iu, nppc
    integer :: np, p
    real, allocatable :: par(:,:)
    real, dimension(1:3) :: vt, vd
    real :: err_max

    ! A: simple drift only, no thermal spread
    il = (/1,1,1/); iu = (/4,4,4/); nppc = (/3,3,3/)
    np = product(iu-il+1) * product(nppc)
    allocate(par(1:6, 1:np))

    vt = 0.0
    vd = (/1.5, -2.0, 3.7/)

    call sub_I01_par_distribute_equilibrium(par, nppc, il, iu, vt, vd)

    err_max = 0.0
    do p = 1, np
        err_max = max(err_max, abs(par(4,p) - vd(1)))
        err_max = max(err_max, abs(par(5,p) - vd(2)))
        err_max = max(err_max, abs(par(6,p) - vd(3)))
    end do

    if (err_max == 0.0) then
        write(*,'("  A: vd=(",f5.1,",",f5.1,",",f5.1,"), all np=",i6," v=vd exactly  PASS")') &
            vd(1), vd(2), vd(3), np
    else
        write(*,'("  A: max|v-vd|=",es10.2,"  FAIL")') err_max
    end if
    deallocate(par)

    ! B: zero drift and zero thermal (all velocities = 0)
    il = (/1,1,1/); iu = (/2,2,2/); nppc = (/2,2,2/)
    np = product(iu-il+1) * product(nppc)
    allocate(par(1:6, 1:np))

    vt = 0.0
    vd = 0.0

    call sub_I01_par_distribute_equilibrium(par, nppc, il, iu, vt, vd)

    err_max = 0.0
    do p = 1, np
        err_max = max(err_max, abs(par(4,p)))
        err_max = max(err_max, abs(par(5,p)))
        err_max = max(err_max, abs(par(6,p)))
    end do

    if (err_max == 0.0) then
        write(*,'("  B: vt=vd=0, all np=",i4," velocities = 0 exactly  PASS")') np
    else
        write(*,'("  B: max|v|=",es10.2,"  FAIL")') err_max
    end if
    deallocate(par)

end subroutine sub_case03_vt0
