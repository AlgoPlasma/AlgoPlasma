module geom_special_common
    use, intrinsic :: ieee_arithmetic
    implicit none
contains

    subroutine parse_int_arg(idx, default_value, out_value)
        implicit none
        integer, intent(in) :: idx, default_value
        integer, intent(out) :: out_value
        character(len=64) :: arg
        integer :: ios

        out_value = default_value
        call get_command_argument(idx, arg)
        if (len_trim(arg) == 0) return
        read(arg, *, iostat=ios) out_value
        if (ios /= 0) out_value = default_value
    end subroutine parse_int_arg


    subroutine parse_real_arg(idx, default_value, out_value)
        implicit none
        integer, intent(in) :: idx
        real, intent(in) :: default_value
        real, intent(out) :: out_value
        character(len=64) :: arg
        integer :: ios

        out_value = default_value
        call get_command_argument(idx, arg)
        if (len_trim(arg) == 0) return
        read(arg, *, iostat=ios) out_value
        if (ios /= 0) out_value = default_value
    end subroutine parse_real_arg


    real function safe_ratio(num, den)
        implicit none
        real, intent(in) :: num, den
        real, parameter :: tiny_den = 1.0e-30
        safe_ratio = num / max(abs(den), tiny_den)
    end function safe_ratio


    real function observed_order(eh, eh2)
        implicit none
        real, intent(in) :: eh, eh2
        real, parameter :: tiny_v = 1.0e-30
        observed_order = log(max(eh,tiny_v)/max(eh2,tiny_v)) / log(2.0)
    end function observed_order


    subroutine update_l2_linf(err, w, sumsq, sumw, linf)
        implicit none
        real, intent(in) :: err, w
        real, intent(inout) :: sumsq, sumw, linf
        sumsq = sumsq + err*err*w
        sumw = sumw + w
        linf = max(linf, abs(err))
    end subroutine update_l2_linf


    integer function region_id(i, nmax, axis_cells)
        implicit none
        integer, intent(in) :: i, nmax, axis_cells
        if (i == 1) then
            region_id = 2    ! first_ring (kept for explicit reporting)
        else if (i <= axis_cells) then
            region_id = 1    ! axis_band
        else if (i >= nmax-2) then
            region_id = 3    ! outer_band
        else
            region_id = 4    ! interior
        end if
    end function region_id


    subroutine print_header(title)
        implicit none
        character(len=*), intent(in) :: title
        write(*,'(A)') '==============================================='
        write(*,'(A)') trim(title)
        write(*,'(A)') '==============================================='
    end subroutine print_header

end module geom_special_common

