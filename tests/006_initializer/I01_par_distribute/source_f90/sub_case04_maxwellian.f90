! Statistical check of the Box-Muller Maxwellian sampler.
! With N=125000 particles: sigma_mean = vt/sqrt(N) ~ vt/354,
! sigma_std  = vt/sqrt(2N) ~ vt/500.
! A 5% tolerance is ~17-25 standard errors: essentially deterministic.
! Outputs velocity data to case04_maxwellian.dat for Python histogram plot.
subroutine sub_case04_maxwellian()
    implicit none

    integer, dimension(1:3) :: il, iu, nppc
    integer :: np, p, unit
    real, allocatable :: par(:,:)
    real, dimension(1:3) :: vt, vd
    real :: mean_v(3), sum_v(3), sum_v2(3), std_v(3)
    logical :: pass_mean, pass_std
    real, parameter :: tol = 0.05   ! 5% of vt

    il = (/1,1,1/); iu = (/10,10,10/); nppc = (/5,5,5/)
    np = product(iu-il+1) * product(nppc)   ! 125000

    vt = (/1.0, 2.0, 3.0/)
    vd = (/0.5, -1.0, 2.0/)

    allocate(par(1:6, 1:np))
    call random_seed()
    call sub_I01_par_distribute_equilibrium(par, nppc, il, iu, vt, vd)

    sum_v  = 0.0
    sum_v2 = 0.0
    do p = 1, np
        sum_v(1)  = sum_v(1)  + par(4,p)
        sum_v(2)  = sum_v(2)  + par(5,p)
        sum_v(3)  = sum_v(3)  + par(6,p)
        sum_v2(1) = sum_v2(1) + par(4,p)**2
        sum_v2(2) = sum_v2(2) + par(5,p)**2
        sum_v2(3) = sum_v2(3) + par(6,p)**2
    end do

    mean_v = sum_v / real(np)
    std_v(1) = sqrt(sum_v2(1)/real(np) - mean_v(1)**2)
    std_v(2) = sqrt(sum_v2(2)/real(np) - mean_v(2)**2)
    std_v(3) = sqrt(sum_v2(3)/real(np) - mean_v(3)**2)

    write(*,'("  np=",i7," vt=(",f4.1,",",f4.1,",",f4.1,")  vd=(",f4.1,",",f4.1,",",f4.1,")")') &
        np, vt(1),vt(2),vt(3), vd(1),vd(2),vd(3)
    write(*,'("  mean: (",f8.4,",",f8.4,",",f8.4,")  expected: (",f4.1,",",f4.1,",",f4.1,")")') &
        mean_v(1),mean_v(2),mean_v(3), vd(1),vd(2),vd(3)
    write(*,'("  std:  (",f8.4,",",f8.4,",",f8.4,")  expected: (",f4.1,",",f4.1,",",f4.1,")")') &
        std_v(1),std_v(2),std_v(3), vt(1),vt(2),vt(3)

    pass_mean = abs(mean_v(1)-vd(1)) < tol*vt(1) .and. &
                abs(mean_v(2)-vd(2)) < tol*vt(2) .and. &
                abs(mean_v(3)-vd(3)) < tol*vt(3)
    pass_std  = abs(std_v(1)-vt(1)) < tol*vt(1) .and. &
                abs(std_v(2)-vt(2)) < tol*vt(2) .and. &
                abs(std_v(3)-vt(3)) < tol*vt(3)

    if (pass_mean .and. pass_std) then
        write(*,'("  mean & std within 5% of target  PASS")')
    else
        if (.not. pass_mean) write(*,'("  mean out of tolerance  FAIL")')
        if (.not. pass_std)  write(*,'("  std  out of tolerance  FAIL")')
    end if

    open(newunit=unit, file='case04_maxwellian.dat', status='replace', action='write')
    write(unit,'("# p vx vy vz")')
    do p = 1, np
        write(unit,'(i8,3(1x,es16.8))') p, par(4,p), par(5,p), par(6,p)
    end do
    close(unit)
    write(*,'("  velocity data written to case04_maxwellian.dat")')

    deallocate(par)

end subroutine sub_case04_maxwellian
