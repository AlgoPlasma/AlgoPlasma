! Verify exact spatial positions against the analytic formula:
!   x = (i-1) + (ip+0.5)/nppc(1)
!   y = (j-1) + (jp+0.5)/nppc(2)
!   z = (k-1) + (kp+0.5)/nppc(3)
! Particles are filled in loop order: k,j,i outer; kp,jp,ip inner.
subroutine sub_case02_positions()
    implicit none

    integer, dimension(1:3) :: il, iu, nppc
    integer :: np, i, j, k, ip, jp, kp, p
    real, allocatable :: par(:,:)
    real, dimension(1:3) :: vt, vd
    real :: x_ana, y_ana, z_ana, err_max
    real, parameter :: tol = 1.0e-6

    vt = 0.0; vd = 0.0

    ! A: single cell il=iu=[2,3,4], nppc=[4,3,2] -> 24 particles
    il = (/2,3,4/); iu = (/2,3,4/); nppc = (/4,3,2/)
    np = product(iu-il+1) * product(nppc)
    allocate(par(1:6, 1:np))
    call sub_I01_par_distribute_equilibrium(par, nppc, il, iu, vt, vd)

    err_max = 0.0
    p = 1
    do k = il(3), iu(3)
    do j = il(2), iu(2)
    do i = il(1), iu(1)
        do kp = 0, nppc(3)-1
        do jp = 0, nppc(2)-1
        do ip = 0, nppc(1)-1
            x_ana = real(i-1) + (real(ip)+0.5) / real(nppc(1))
            y_ana = real(j-1) + (real(jp)+0.5) / real(nppc(2))
            z_ana = real(k-1) + (real(kp)+0.5) / real(nppc(3))
            err_max = max(err_max, abs(par(1,p)-x_ana))
            err_max = max(err_max, abs(par(2,p)-y_ana))
            err_max = max(err_max, abs(par(3,p)-z_ana))
            p = p + 1
        end do
        end do
        end do
    end do
    end do
    end do

    if (err_max < tol) then
        write(*,'("  A: single cell 4x3x2 ppc, max_err=",es10.2,"  PASS")') err_max
    else
        write(*,'("  A: single cell 4x3x2 ppc, max_err=",es10.2,"  FAIL (tol=",es10.2,")")') err_max, tol
    end if
    deallocate(par)

    ! B: 2x2x2 cells, nppc=[2,2,2] -> 64 particles
    il = (/1,2,3/); iu = (/2,3,4/); nppc = (/2,2,2/)
    np = product(iu-il+1) * product(nppc)
    allocate(par(1:6, 1:np))
    call sub_I01_par_distribute_equilibrium(par, nppc, il, iu, vt, vd)

    err_max = 0.0
    p = 1
    do k = il(3), iu(3)
    do j = il(2), iu(2)
    do i = il(1), iu(1)
        do kp = 0, nppc(3)-1
        do jp = 0, nppc(2)-1
        do ip = 0, nppc(1)-1
            x_ana = real(i-1) + (real(ip)+0.5) / real(nppc(1))
            y_ana = real(j-1) + (real(jp)+0.5) / real(nppc(2))
            z_ana = real(k-1) + (real(kp)+0.5) / real(nppc(3))
            err_max = max(err_max, abs(par(1,p)-x_ana))
            err_max = max(err_max, abs(par(2,p)-y_ana))
            err_max = max(err_max, abs(par(3,p)-z_ana))
            p = p + 1
        end do
        end do
        end do
    end do
    end do
    end do

    if (err_max < tol) then
        write(*,'("  B: 2x2x2 cells 2x2x2 ppc, max_err=",es10.2,"  PASS")') err_max
    else
        write(*,'("  B: 2x2x2 cells 2x2x2 ppc, max_err=",es10.2,"  FAIL (tol=",es10.2,")")') err_max, tol
    end if
    deallocate(par)

end subroutine sub_case02_positions
