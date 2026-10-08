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
        integer :: event, i, k, face, direction, crossing
        real :: tr, tz, t_hit, duration, uz_before, time_tolerance
        logical :: alive, hit_r, hit_z

        alive = .true.
        do event = 1, max_events
            i = fun_J01_locate_cell(r, r_edge)
            k = fun_J01_locate_cell(z, z_edge)
            if (i < 1 .or. k < 1) exit
            if (.not. active(i, k)) exit
            ! Distances / signed velocity give positive times to the next face.
            ! huge disables a direction when its velocity is zero.
            tr = huge(1.0)
            tz = huge(1.0)
            if (ur > 0.0) tr = (r_edge(i+1)-r)/ur
            if (ur < 0.0) tr = (r_edge(i)-r)/ur
            if (uz > 0.0) tz = (z_edge(k+1)-z)/uz
            if (uz < 0.0) tz = (z_edge(k)-z)/uz
            if (tr <= 0.0) tr = huge(1.0)
            if (tz <= 0.0) tz = huge(1.0)
            t_hit = min(tr, tz)
            if (t_hit >= huge(1.0)*0.5) then
                exit
            end if

            ! Accumulate before handling the event: this segment belongs to the
            ! current cell. The small post-event offset has no residence time.
            duration = t_hit
            tally%residence(i, k) = tally%residence(i, k)+duration
            tally%moment_r(i, k) = tally%moment_r(i, k)+ur*duration
            tally%moment_z(i, k) = tally%moment_z(i, k)+uz*duration
            r = r+ur*duration
            z = z+uz*duration
            ! Only roundoff-level ties are corners; nearby distinct hits keep
            ! their physical order, regardless of the grid/time units.
            time_tolerance = 16.0*epsilon(1.0)*t_hit
            hit_r = abs(tr-t_hit) <= time_tolerance
            hit_z = abs(tz-t_hit) <= time_tolerance
            ! Snap every counted hit to its face before the gas-side offset.
            ! Otherwise a counted crossing can still locate in the old cell.
            ! Each offset below is at least one representable step toward its target side.
            if (hit_r) r = r_edge(i+merge(1,0,ur > 0.0))
            if (hit_z) z = z_edge(k+merge(1,0,uz > 0.0))
            uz_before = uz

            if (hit_r) then
                ! Keep the incident direction: reflection changes ur before
                ! the position is moved back onto the gas side of the wall.
                direction = merge(1, -1, ur > 0.0)
                face = merge(J01_R_HI, J01_R_LO, ur > 0.0)
                crossing = i+min(direction, 0)
                select case (face_type(face, i, k))
                case (J01_FACE_INTERIOR)
                    tally%count_r(crossing, k) = tally%count_r(crossing, k)+real(direction)
                    r = r+direction*max(eps_r, &
                        abs(nearest(r, real(direction))-r))
                    i = i+direction
                case (J01_FACE_OPEN)
                    tally%boundary_count(face, i, k) = tally%boundary_count(face, i, k)+real(direction)
                    alive = .false.
                case default
                    call sub_J01_reflect_velocity(ur, uz, face, diffuse_fraction, sigma_wall)
                    r = r-direction*max(eps_r, &
                        abs(nearest(r, -real(direction))-r))
                end select
                if (.not. alive) exit
            end if
            ! Resolve a corner radially first, then through the axial face of
            ! the resulting cell. This is a connected path with zero residence
            ! in the intermediate cell, not two exits from the original cell.
            ! A diffuse radial reflection may turn the axial velocity inward.
            if (hit_z .and. hit_r) then
                if ((uz_before > 0.0 .and. uz <= 0.0) .or. &
                    (uz_before < 0.0 .and. uz >= 0.0)) then
                    z = z-sign(max(eps_z, &
                        abs(nearest(z, -sign(1.0, uz_before))-z)), uz_before)
                    hit_z = .false.
                end if
            end if
            if (hit_z) then
                direction = merge(1, -1, uz > 0.0)
                face = merge(J01_Z_HI, J01_Z_LO, uz > 0.0)
                crossing = k+min(direction, 0)
                select case (face_type(face, i, k))
                case (J01_FACE_INTERIOR)
                    tally%count_z(i, crossing) = tally%count_z(i, crossing)+real(direction)
                    z = z+direction*max(eps_z, &
                        abs(nearest(z, real(direction))-z))
                case (J01_FACE_OPEN)
                    tally%boundary_count(face, i, k) = tally%boundary_count(face, i, k)+real(direction)
                    alive = .false.
                case default
                    call sub_J01_reflect_velocity(ur, uz, face, diffuse_fraction, sigma_wall)
                    z = z-direction*max(eps_z, &
                        abs(nearest(z, -real(direction))-z))
                end select
                if (.not. alive) exit
            end if
        end do

        ! Only an OPEN face completes a history; all other exits are incomplete.
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
