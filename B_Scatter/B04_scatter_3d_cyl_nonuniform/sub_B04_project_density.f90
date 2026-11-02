!> @brief Compute cell-volume-averaged number or charge density from a
!> trilinear nodal field on a structured tensor-product cylindrical grid
!> allowing nonuniform coordinate spacing.
!> @author Xin Luo (2026/10/31)
!>
!> @details
!> Integrate the trilinear nodal field over each cell using the cylindrical
!> volume measure, then divide by the cell volume:
!> @f[
!> \overline D_{ijk}=\frac14\sum_{b,c=0}^{1}
!> [\beta_L D_{i,j+b,k+c}+\beta_R D_{i+1,j+b,k+c}],
!> \qquad
!> \beta_L=\frac{2r_i+r_{i+1}}{3(r_i+r_{i+1})},
!> \quad \beta_R=1-\beta_L.
!> @f]
!> wl and wr hold the radial weights. Angular and axial widths cancel
!> in the normalized integrals, giving endpoint weights of 1/2 in each
!> direction; only radial coordinates are needed by this interface.
!> With periodic_phi, the last angular cell uses node zero as its upper node.
!>
!> Each output entry represents the reconstructed field's volume average
!> over one cell. Use this optional operation when downstream source
!> assembly requires cell averages.
!> Near the floating-point limit, local nodal values are scaled before
!> averaging; the normalized convex mean is bounded before restoring its scale.
!>
!> @param[in] r Finite, strictly increasing radial nodes r(0:nr), with nr>=1
!> and r(0)>=0. Retain the physical radius; r(0)>0 describes an annulus.
!> @param[in] periodic_phi If true, identify the two angular endpoints and
!> store only independent angular nodes in density; otherwise retain both endpoints.
!> @param[in] density Finite nodal number or charge density after required
!> shared-node summation and full-circle axis averaging, when applicable.
!> Layout: (0:nr,0:nphi-1,0:nz) for periodic phi, or (0:nr,0:nphi,0:nz) otherwise.
!> @param[inout] cell_density Preallocated cell-volume averages with layout
!> (0:nr-1,0:nphi-1,0:nz-1), fully overwritten on success. Units match density.
!> @param[out] ierr B04 status; see @ref b04_return_status "module return-status definitions".
!> Checks cover radial coordinates, array shapes and finiteness of input density.
!>
!> @note nr, nphi and nz are cell counts, each at least one. nr is inferred
!> from r; nphi and nz are inferred from density and the periodic setting.
!> The first element of each actual array maps to dummy index zero.
!> @note The caller allocates cell_density; its initial values are unused.
!> A nonzero returned status leaves cell_density unchanged.
!> @see @ref sub_b04_scatter_3d_cyl_nonuniform "sub_B04_scatter_3d_cyl_nonuniform",
!> @ref sub_b04_average_axis "sub_B04_average_axis"
subroutine sub_B04_project_density(r, periodic_phi, density, cell_density, ierr)
    real, intent(in) :: r(0:), density(0:,0:,0:)
    logical, intent(in) :: periodic_phi
    real, intent(inout) :: cell_density(0:,0:,0:)
    integer, intent(out) :: ierr
    integer :: nr, na, nz, i, j, k, jp, b, c
    real :: wl, wr, ratio, nodes(0:1,0:1,0:1), density_scale

    ierr = B04_BAD_GRID
    if (.not. valid_coordinates(r)) return
    if (r(0) < 0.0) return
    nr = size(r)-1
    na = size(density,2)-1
    if (periodic_phi) na = size(density,2)
    nz = size(density,3)-1
    ierr = B04_BAD_SHAPE
    if (na < 1 .or. nz < 1) return
    if (size(density,1) /= nr+1) return
    if (any(shape(cell_density) /= [nr,na,nz])) return
    ierr = B04_BAD_VALUE
    if (.not. all(ieee_is_finite(density))) return

    cell_density = 0.0
    do i = 0, nr-1
        ! Equivalent to (2*rL+rR)/(3*(rL+rR)), avoiding a large-radius sum.
        ratio = r(i)/r(i+1)
        wl = (2.0*ratio+1.0)/(3.0*(ratio+1.0))
        wr = 1.0-wl
        do k = 0, nz-1
        do j = 0, na-1
            do c = 0, 1
            do b = 0, 1
                jp = j+b
                if (periodic_phi) jp = modulo(jp,na)
                nodes(:,b,c) = density(i:i+1,jp,k+c)
            end do
            end do
            density_scale = maxval(abs(nodes))
            ! Retain the direct sum away from the floating-point upper limit.
            if (density_scale > huge(1.0)/2.0) nodes = nodes/density_scale
            do c = 0, 1
            do b = 0, 1
                cell_density(i,j,k) = cell_density(i,j,k) &
                    + (wl/4.0)*nodes(0,b,c) + (wr/4.0)*nodes(1,b,c)
            end do
            end do
            if (density_scale > huge(1.0)/2.0) then
                ! A convex mean of values in [-1,1] stays in [-1,1]. Bound
                ! roundoff at the endpoints before rescaling to avoid overflow.
                cell_density(i,j,k) = density_scale*max(-1.0,min(1.0,cell_density(i,j,k)))
            end if
        end do
        end do
    end do
    ierr = B04_OK
end subroutine sub_B04_project_density
