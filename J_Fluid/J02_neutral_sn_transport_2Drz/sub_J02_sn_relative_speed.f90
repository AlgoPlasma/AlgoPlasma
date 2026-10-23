!> Relative speed and the node reconstruction/coordinate conversion needed to evaluate it.

    !> Reconstruct physical components in the SAME local orthonormal (r,phi,z) basis.
    !> velocity(3,n_dir) is in m/s, ordered (v_r,v_phi,v_z); v_phi is zero in J02.
    !> The three-slot representation does not extend the transport model to 2D3V.
    !> quadrature must be successfully initialized; ierr is retained for source compatibility.
    subroutine sub_J02_build_velocity_vectors(quadrature, velocity, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, allocatable, intent(out) :: velocity(:,:)
        integer, intent(out) :: ierr

        allocate(velocity(3,quadrature%n_dir))
        velocity(1,:) = quadrature%speed*quadrature%mu
        velocity(2,:) = 0.0
        velocity(3,:) = quadrature%speed*quadrature%eta
        ierr = SN_SUCCESS
    end subroutine sub_J02_build_velocity_vectors

    !> Rotate physical (v_r,v_phi,v_z) into (v_x,v_y,v_z), both in m/s.
    !> azimuth is the SPACE position angle in radians, not the SN velocity angle.
    !> v_phi is tangential speed r*dphi/dt, not angular velocity dphi/dt.
    !> Inputs must be finite and the resulting components representable.
    pure function fun_J02_velocity_cyl_to_cart(velocity_cyl, azimuth) result(velocity_xyz)
        real, intent(in) :: velocity_cyl(3), azimuth
        real :: velocity_xyz(3), c, s

        c = cos(azimuth)
        s = sin(azimuth)
        velocity_xyz(1) = c*velocity_cyl(1)-s*velocity_cyl(2)
        velocity_xyz(2) = s*velocity_cyl(1)+c*velocity_cyl(2)
        velocity_xyz(3) = velocity_cyl(3)
    end function fun_J02_velocity_cyl_to_cart

    !> Relative speed [m/s] of vectors expressed in the SAME orthonormal basis.
    !> This can be a common local (r,phi,z) basis or a global Cartesian basis.
    !> Different local azimuths must be rotated to a common basis before this call.
    !> Inputs, component differences and their norm must be finite/representable.
    !> Scaling avoids overflow/underflow from squaring otherwise valid differences.
    pure real function fun_J02_relative_speed(velocity_a, velocity_b) result(relative_speed)
        real, intent(in) :: velocity_a(3), velocity_b(3)
        real :: delta(3), scale

        delta = velocity_a-velocity_b
        scale = maxval(abs(delta))
        relative_speed = 0.0
        if (scale <= 0.0) return
        relative_speed = scale*sqrt(sum((delta/scale)**2))
    end function fun_J02_relative_speed
