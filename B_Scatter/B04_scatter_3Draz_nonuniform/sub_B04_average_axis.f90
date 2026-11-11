!> @brief Make nodal number or charge density single-valued on the r=0
!> axis of a structured cylindrical grid allowing nonuniform spacing.
!> @author Xin Luo (2026/10/31)
!>
!> @details
!> At each axial position, all angular indices on r=0 represent the same
!> physical point. Replace their densities by a common weighted mean:
!> @f[
!> D_{0,j,k}\leftarrow
!> \frac{\sum_{\ell} A_{\ell}D_{0,\ell,k}}{\sum_{\ell} A_{\ell}}.
!> @f]
!> Here A_j is phi_measure(j), the angular nodal basis integral prepared
!> by sub_B04_build_geometry. At a fixed axial position, these weights
!> are proportional to the effective nodal volumes, so the update
!> preserves the volume-weighted particle number or charge to roundoff.
!> Equal angular spacing reduces the operation to an arithmetic mean.
!> Near the floating-point upper limit, densities are scaled before averaging;
!> the normalized mean is bounded to [-1,1] before restoring its magnitude.
!>
!> Supply the full-circle axis after deposition and shared-node summation,
!> including each independent angular node once. The routine overwrites
!> the supplied axis plane in place; its shape and density units are retained.
!>
!> @param[in] phi_measure Positive, finite angular nodal basis integrals,
!> in radians, from sub_B04_build_geometry for the same grid. The length
!> must equal the first dimension of axis_density. Normalization is performed here.
!> @param[inout] axis_density Finite nodal number or charge density on r=0,
!> indexed by angular node then axial node, e.g. density(0,:,:). Both dimensions
!> must be nonempty. On success, all angular entries at each axial node share
!> the weighted mean of the input densities.
!> @param[out] ierr B04 status; see @ref b04_return_status "module return-status definitions".
!> Checks cover the array shapes, weights and input densities. The weight sum
!> and all computed means must also be finite.
!>
!> @note The caller supplies the r=0 plane of a full-circle grid, with each
!> independent angular node represented once. Exclude duplicate periodic
!> endpoints and duplicate MPI copies after shared-node contributions are summed.
!> @note Retain each angular entry's own effective nodal volume when computing
!> total particle number or charge from the averaged densities.
!> @note A nonzero returned status leaves axis_density unchanged.
!> @see @ref sub_b04_build_geometry "sub_B04_build_geometry",
!> @ref sub_b04_scatter_3draz_nonuniform "sub_B04_scatter_3Draz_nonuniform"
subroutine sub_B04_average_axis(phi_measure, axis_density, ierr)
    real, intent(in) :: phi_measure(0:)
    real, intent(inout) :: axis_density(0:,0:)
    integer, intent(out) :: ierr
    real :: mean(0:size(axis_density,2)-1), total, density_scale
    integer :: k

    ierr = B04_BAD_SHAPE
    if (size(phi_measure) < 1 .or. size(axis_density,2) < 1) return
    if (size(phi_measure) /= size(axis_density,1)) return
    ierr = B04_BAD_VOLUME
    if (.not. all(ieee_is_finite(phi_measure))) return
    if (any(phi_measure <= 0.0)) return
    total = sum(phi_measure)
    if (.not. ieee_is_finite(total)) return
    ierr = B04_BAD_VALUE
    if (.not. all(ieee_is_finite(axis_density))) return
    do k = 0, size(axis_density,2)-1
        density_scale = maxval(abs(axis_density(:,k)))
        if (density_scale > huge(1.0)/2.0) then
            mean(k) = sum((phi_measure/total)*(axis_density(:,k)/density_scale))
            if (.not. ieee_is_finite(mean(k))) return
            ! A normalized positive-weight mean lies in [-1,1]. Bound
            ! endpoint roundoff before rescaling, as in cell projection.
            mean(k) = density_scale*max(-1.0,min(1.0,mean(k)))
        else
            mean(k) = sum((phi_measure/total)*axis_density(:,k))
        end if
        if (.not. ieee_is_finite(mean(k))) return
    end do
    do k = 0, size(axis_density,2)-1
        axis_density(:,k) = mean(k)
    end do
    ierr = B04_OK
end subroutine sub_B04_average_axis
