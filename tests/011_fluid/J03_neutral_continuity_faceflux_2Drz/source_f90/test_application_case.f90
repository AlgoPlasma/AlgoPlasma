program test_application_case
    use mod_application_case
    implicit none
    logical, allocatable :: mask(:,:)
    logical :: active(1,1)
    real :: r(2), z(2), loss(1,1)
    integer :: failed
    failed = 0
    call build_case_mask(mask)
    call check(count(mask) == 56320, 'active-cell count')
    call check(.not. mask(64,72) .and. mask(65,72) .and. mask(1,73), 'channel and plume interface')
    active = .true.
    r = [0.013683098220475191,0.024672244366128356]
    z = [0.0024709824265487373,0.010022411397665104]
    call build_case_loss(r,z,active,.true.,loss)
    call check(abs(loss(1,1)-1.e5) < 1.e-8, 'ION window has prescribed centre peak')
    call build_case_loss(r,z,active,.false.,loss)
    call check(abs(loss(1,1)) < tiny(1.0), 'B0 has no volume loss')
    active = .false.
    call build_case_loss(r,z,active,.true.,loss)
    call check(abs(loss(1,1)) < tiny(1.0), 'inactive cell has no loss')
    active = .true.
    r = [0.04,0.05]
    call build_case_loss(r,z,active,.true.,loss)
    call check(abs(loss(1,1)) < tiny(1.0), 'outside window has no loss')
    write(*,'(a,i0)') 'n_failed = ',failed
    if (failed /= 0) error stop 1
    write(*,'(a)') 'RESULT: PASS'
contains
    subroutine check(ok, message)
        logical, intent(in) :: ok
        character(len=*), intent(in) :: message
        if (ok) then
            write(*,'(a)') 'PASS: '//message
        else
            failed = failed+1
            write(*,'(a)') 'FAIL: '//message
        end if
    end subroutine check
end program test_application_case
