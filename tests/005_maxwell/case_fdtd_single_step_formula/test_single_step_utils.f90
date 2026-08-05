module test_single_step_utils

implicit none

type :: report_t
    real :: max_abs_err = 0.0
    real :: max_rel_err = 0.0
    integer :: n_failed = 0
end type report_t

contains

subroutine report_init(rep)
    implicit none
    type(report_t), intent(inout) :: rep
    rep%max_abs_err = 0.0
    rep%max_rel_err = 0.0
    rep%n_failed = 0
end subroutine report_init


subroutine report_check(rep, point_type, comp, i, j, k, ref_val, num_val, tol_abs, tol_rel)
    implicit none
    type(report_t), intent(inout) :: rep
    character(len=*), intent(in) :: point_type, comp
    integer, intent(in) :: i, j, k
    real, intent(in) :: ref_val, num_val, tol_abs, tol_rel

    real :: abs_err, rel_err, denom

    abs_err = abs(num_val-ref_val)
    denom = max(abs(ref_val), 1.0e-14)
    rel_err = abs_err/denom

    rep%max_abs_err = max(rep%max_abs_err, abs_err)
    rep%max_rel_err = max(rep%max_rel_err, rel_err)

    if (abs_err > tol_abs .and. rel_err > tol_rel) then
        rep%n_failed = rep%n_failed + 1
        write(*,'(A,A,A,A,A,3(I0,A),A,1PE14.6,A,1PE14.6,A,1PE11.3,A,1PE11.3)') &
            '  FAIL point_type=',trim(point_type),', comp=',trim(comp),', idx=(', &
            i,',',j,',',k,')',', ref=',ref_val,', num=',num_val,', abs=',abs_err,', rel=',rel_err
    end if
end subroutine report_check


subroutine report_print(title, rep)
    implicit none
    character(len=*), intent(in) :: title
    type(report_t), intent(in) :: rep

    write(*,'(A)') trim(title)
    write(*,'(A,1PE12.4)') '  max_abs_err = ', rep%max_abs_err
    write(*,'(A,1PE12.4)') '  max_rel_err = ', rep%max_rel_err
    write(*,'(A,I0)')      '  n_failed    = ', rep%n_failed
end subroutine report_print


subroutine project_max_over_k(nx,ny,nz,err3d,err2d)
    implicit none
    integer, intent(in) :: nx, ny, nz
    real, intent(in) :: err3d(0:nx,0:ny,0:nz)
    real, intent(out) :: err2d(0:nx,0:ny)
    integer :: i, j, k

    err2d = 0.0
    do k = 0, nz
    do j = 0, ny
    do i = 0, nx
        err2d(i,j) = max(err2d(i,j), err3d(i,j,k))
    end do
    end do
    end do
end subroutine project_max_over_k


subroutine project_max_over_j(nx,ny,nz,err3d,err2d)
    implicit none
    integer, intent(in) :: nx, ny, nz
    real, intent(in) :: err3d(0:nx,0:ny,0:nz)
    real, intent(out) :: err2d(0:nx,0:nz)
    integer :: i, j, k

    err2d = 0.0
    do k = 0, nz
    do j = 0, ny
    do i = 0, nx
        err2d(i,k) = max(err2d(i,k), err3d(i,j,k))
    end do
    end do
    end do
end subroutine project_max_over_j


subroutine write_pgm_2d(filename,nx,ny,err2d)
    implicit none
    character(len=*), intent(in) :: filename
    integer, intent(in) :: nx, ny
    real, intent(in) :: err2d(0:nx,0:ny)
    integer :: i, j, iu, pixel
    real :: vmax, scale, value

    vmax = maxval(err2d)
    if (vmax > 0.0) then
        scale = 255.0/vmax
    else
        scale = 0.0
    end if

    open(newunit=iu,file=trim(filename),status='replace',action='write',form='formatted')
    write(iu,'(A)') 'P2'
    write(iu,'(I0,1X,I0)') nx+1, ny+1
    write(iu,'(I0)') 255

    do j = ny, 0, -1
        do i = 0, nx
            value = err2d(i,j)*scale
            if (value < 0.0) value = 0.0
            if (value > 255.0) value = 255.0
            pixel = nint(value)
            write(iu,'(I0,1X)',advance='no') pixel
        end do
        write(iu,*)
    end do

    close(iu)
end subroutine write_pgm_2d

end module test_single_step_utils
