!> Normalize any nonnegative inlet shape to a prescribed incoming number flux.
!> Model-specific shapes live in sub_J02_sn_inflow.f90; removal lives in sub_J02_sn_loss.f90.
    subroutine sub_J02_normalize_inflow_flux(quadrature, normal_r, normal_z, &
        target_flux, inflow_shape, psi_in, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: normal_r, normal_z, target_flux
        real, intent(in) :: inflow_shape(:)
        real, allocatable, intent(out) :: psi_in(:)
        integer, intent(out) :: ierr
        real :: ndot(quadrature%n_dir), denominator

        ierr = fun_J02_validate_inflow_input(quadrature, normal_r, normal_z, inflow_shape, target_flux)
        if (ierr /= SN_SUCCESS) return

        ndot = quadrature%mu*normal_r+quadrature%eta*normal_z
        denominator = sum(quadrature%weight*quadrature%speed*(-ndot)*inflow_shape, mask=ndot < 0.0)
        if (denominator <= tiny(denominator)) then
            ierr = SN_ERR_SOURCE_ZERO_NORMALIZATION
            return
        end if
        allocate(psi_in(quadrature%n_dir))
        psi_in = 0.0
        where (ndot < 0.0) psi_in = target_flux*inflow_shape/denominator
    end subroutine sub_J02_normalize_inflow_flux
