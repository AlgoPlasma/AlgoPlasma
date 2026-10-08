!> Specular or flux-weighted diffuse reflection at a wall.
    subroutine sub_J01_reflect_velocity(ur, uz, face, diffuse_fraction, sigma_wall)
        real, intent(inout) :: ur, uz
        integer, intent(in) :: face
        real, intent(in) :: diffuse_fraction, sigma_wall
        real :: u, vn, vt
        call random_number(u)
        if (u >= diffuse_fraction) then
            if (face == J01_R_LO .or. face == J01_R_HI) then
                ur = -ur
            else
                uz = -uz
            end if
            return
        end if
        call random_number(u)
        u = max(u, tiny(1.0))
        vn = sigma_wall*sqrt(-2.0*log(u))
        vt = sigma_wall*fun_J01_standard_normal()
        select case (face)
          case (J01_R_LO)
            ur = vn
            uz = vt
          case (J01_R_HI)
            ur = -vn
            uz = vt
          case (J01_Z_LO)
            ur = vt
            uz = vn
          case (J01_Z_HI)
            ur = vt
            uz = -vn
        end select
    end subroutine sub_J01_reflect_velocity
