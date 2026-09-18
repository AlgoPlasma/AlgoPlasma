!> Advance one history; input position/velocity are updated in place.
!> Grid topology must identify valid neighbours on every interior face.
    subroutine sub_J01_trace_fm_history(r_edge, z_edge, active, face_type, diffuse_fraction, &
        sigma_wall, max_events, eps_r, eps_z, r, z, ur, uz, tally, escaped, truncated)
        real, intent(in) :: r_edge(:), z_edge(:), diffuse_fraction, sigma_wall, eps_r, eps_z
        logical, intent(in) :: active(:, :)
        integer, intent(in) :: face_type(:, :, :), max_events
        real, intent(inout) :: r, z, ur, uz
        type(fm_tally_2drz_type), intent(inout) :: tally
        logical, intent(out) :: escaped, truncated
        integer :: event, i, k, face
        real :: tr, tz, t_hit, duration
        logical :: alive, hit_r, hit_z

        alive = .true.
        do event = 1, max_events
            i = fun_J01_locate_cell(r, r_edge)
            k = fun_J01_locate_cell(z, z_edge)
            if (i < 1 .or. k < 1) exit
            if (.not. active(i, k)) exit
            tr = huge(1.0)
            tz = huge(1.0)
            if (ur > 0.0) tr = (r_edge(i+1)-r)/ur
            if (ur < 0.0) tr = (r_edge(i)-r)/ur
            if (uz > 0.0) tz = (z_edge(k+1)-z)/uz
            if (uz < 0.0) tz = (z_edge(k)-z)/uz
            if (tr <= 1.0e-14) tr = huge(1.0)
            if (tz <= 1.0e-14) tz = huge(1.0)
            t_hit = min(tr, tz)
            if (t_hit >= huge(1.0)*0.5) then
                exit
            end if

            duration = t_hit
            tally%residence(i, k) = tally%residence(i, k)+duration
            tally%moment_r(i, k) = tally%moment_r(i, k)+ur*duration
            tally%moment_z(i, k) = tally%moment_z(i, k)+uz*duration
            r = r+ur*duration
            z = z+uz*duration
            hit_r = abs(tr-t_hit) <= 1.0e-12
            hit_z = abs(tz-t_hit) <= 1.0e-12

            if (hit_r) then
                if (ur > 0.0) then
                    face = face_type(J01_R_HI, i, k)
                    if (face == J01_FACE_INTERIOR) then
                        tally%count_r(i, k) = tally%count_r(i, k)+1.0
                        r = r+eps_r
                    else if (face == J01_FACE_OPEN) then
                        tally%boundary_count(J01_R_HI, i, k) = tally%boundary_count(J01_R_HI, i, k)+1.0
                        alive = .false.
                    else
                        call sub_J01_reflect_velocity(ur, uz, J01_R_HI, &
                            diffuse_fraction, sigma_wall)
                        r = r-eps_r
                    end if
                else
                    face = face_type(J01_R_LO, i, k)
                    if (face == J01_FACE_INTERIOR) then
                        tally%count_r(i-1, k) = tally%count_r(i-1, k)-1.0
                        r = r-eps_r
                    else if (face == J01_FACE_OPEN) then
                        tally%boundary_count(J01_R_LO, i, k) = tally%boundary_count(J01_R_LO, i, k)-1.0
                        alive = .false.
                    else
                        call sub_J01_reflect_velocity(ur, uz, J01_R_LO, &
                            diffuse_fraction, sigma_wall)
                        r = r+eps_r
                    end if
                end if
                if (.not. alive) exit
            end if
            if (hit_z) then
                if (uz > 0.0) then
                    face = face_type(J01_Z_HI, i, k)
                    if (face == J01_FACE_INTERIOR) then
                        tally%count_z(i, k) = tally%count_z(i, k)+1.0
                        z = z+eps_z
                    else if (face == J01_FACE_OPEN) then
                        tally%boundary_count(J01_Z_HI, i, k) = tally%boundary_count(J01_Z_HI, i, k)+1.0
                        alive = .false.
                    else
                        call sub_J01_reflect_velocity(ur, uz, J01_Z_HI, &
                            diffuse_fraction, sigma_wall)
                        z = z-eps_z
                    end if
                else
                    face = face_type(J01_Z_LO, i, k)
                    if (face == J01_FACE_INTERIOR) then
                        tally%count_z(i, k-1) = tally%count_z(i, k-1)-1.0
                        z = z-eps_z
                    else if (face == J01_FACE_OPEN) then
                        tally%boundary_count(J01_Z_LO, i, k) = tally%boundary_count(J01_Z_LO, i, k)-1.0
                        alive = .false.
                    else
                        call sub_J01_reflect_velocity(ur, uz, J01_Z_LO, &
                            diffuse_fraction, sigma_wall)
                        z = z+eps_z
                    end if
                end if
                if (.not. alive) exit
            end if
        end do

        escaped = .not. alive
        truncated = alive
    end subroutine sub_J01_trace_fm_history

    integer function fun_J01_locate_cell(x, edge)
        real, intent(in) :: x, edge(:)
        integer :: lo, hi, mid
        fun_J01_locate_cell = -1
        if (x < edge(1) .or. x >= edge(size(edge))) return
        lo = 1
        hi = size(edge)-1
        do while(lo <= hi)
            mid = (lo+hi)/2
            if (x < edge(mid)) then
                hi = mid-1
            else if (x >= edge(mid+1)) then
                lo = mid+1
            else
                fun_J01_locate_cell = mid
                return
            end if
        end do
    end function fun_J01_locate_cell
