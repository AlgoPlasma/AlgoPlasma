    function fun_J03_error_message(ierr) result(message)
        integer, intent(in) :: ierr
        character(len = 160) :: message
        select case (ierr)
          case (J03_SUCCESS)
            message = 'success'
          case (J03_ERR_SHAPE)
            message = 'one or more J03 input arrays have inconsistent shapes'
          case (J03_ERR_GEOMETRY)
            message = 'active-cell volumes and face areas must be positive'
          case (J03_ERR_NEGATIVE_INPUT)
            message = 'density, loss frequency, or source input is negative'
          case (J03_ERR_FACE_TYPE)
            message = 'face type is invalid or inconsistent with active neighbors'
          case (J03_ERR_OPTIONS)
            message = 'CFL, tolerance, density floor, or iteration count is invalid'
          case (J03_ERR_NOT_CONVERGED)
            message = 'steady continuity iteration reached max_iterations'
          case default
            write(message, '(a,i0)') 'unknown J03 error code: ', ierr
        end select
    end function fun_J03_error_message
