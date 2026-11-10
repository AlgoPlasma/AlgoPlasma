!> @brief Prepare inverse effective nodal volumes and angular integration
!> weights for linear CIC deposition on a three-dimensional structured
!> tensor-product cylindrical grid allowing nonuniform coordinate spacing.
!> @author Xin Luo (2026/10/31)
!>
!> @details
!> The effective volume integrates the linear nodal basis S_ijk over the
!> physical domain Omega using the cylindrical volume measure:
!> @f[ V_{ijk}=\int_{\Omega} S_{ijk}(r,\phi,z)\,r\,dr\,d\phi\,dz. @f]
!> inv_volume stores 1/V for density deposition. phi_measure stores the
!> angular basis integrals used by sub_B04_average_axis.
!> Radial and axial endpoints receive one-sided contributions. Angular
!> endpoints do likewise when nonperiodic; periodic endpoint contributions
!> are combined at node zero.
!> Recompute these arrays when the grid or periodic configuration changes.
!>
!> @param[in] r Finite, strictly increasing radial nodes r(0:nr), with nr>=1
!> and r(0)>=0. Retain the physical radius; r(0)>0 describes an annulus.
!> @param[in] phi Finite, strictly increasing angular nodes phi(0:nphi), in
!> radians, with nphi>=1. Include both endpoints for either periodic setting.
!> @param[in] z Finite, strictly increasing axial nodes z(0:nz), with nz>=1,
!> including both physical endpoints. Use the same length unit as r.
!> @param[in] periodic_phi If true, identify the two angular endpoints and
!> retain nphi independent angular nodes; if false, retain nphi+1 nodes.
!> @param[inout] inv_volume Preallocated inverse effective nodal volumes,
!> overwritten on success. Layout: (0:nr,0:nphi-1,0:nz) for periodic phi,
!> or (0:nr,0:nphi,0:nz) otherwise. Units are m^-3 when r and z are in metres.
!> @param[inout] phi_measure Preallocated angular nodal basis integrals, in
!> radians, overwritten on success. Layout: (0:nphi-1) for periodic phi,
!> or (0:nphi) otherwise. These provide the angular weights for axis averaging.
!> @param[out] ierr B04 status; see @ref b04_return_status "module return-status definitions".
!> Checks cover all coordinate arrays, output shapes and computed nodal volumes.
!> The volumes must be finite and exceed the rounded reciprocal limit 1/huge(1.0).
!>
!> @note nr, nphi and nz are cell counts, each equal to its coordinate-array
!> length minus one. The first element of each actual array maps to dummy index zero.
!> @note The caller allocates both output arrays; initial values are unused.
!> A nonzero returned status leaves both arrays unchanged.
!> @note Radial and axial array endpoints are treated as physical endpoints.
!> For MPI interface nodes, use complete nodal volumes including the basis
!> support on both sides of the interface.
!> @see @ref sub_b04_scatter_3d_raz_nonuniform "sub_B04_scatter_3d_raz_nonuniform",
!> @ref sub_b04_average_axis "sub_B04_average_axis"
subroutine sub_B04_build_geometry(r, phi, z, periodic_phi, inv_volume, phi_measure, ierr)
    real, intent(in) :: r(0:), phi(0:), z(0:)
    logical, intent(in) :: periodic_phi
    real, intent(inout) :: inv_volume(0:,0:,0:), phi_measure(0:)
    integer, intent(out) :: ierr
    ! Separable nodal integrals in r dr, dphi and dz, respectively.
    real :: vr(0:size(r)-1), va(0:size(phi)-1), vz(0:size(z)-1)
    real :: h, volume
    ! na counts angular cells; nj counts stored angular nodes.
    integer :: i, j, k, na, nj

    ierr = B04_BAD_GRID
    if (.not. valid_coordinates(r)) return
    if (.not. valid_coordinates(phi)) return
    if (.not. valid_coordinates(z)) return
    if (r(0) < 0.0) return
    na = size(phi)-1
    nj = na+1
    if (periodic_phi) nj = na
    ierr = B04_BAD_SHAPE
    if (any(shape(inv_volume) /= [size(r),nj,size(z)])) return
    if (size(phi_measure) /= nj) return

    vr = 0.0
    va = 0.0
    vz = 0.0
    do i = 0, size(r)-2
        h = r(i+1)-r(i)
        vr(i) = vr(i) + h*(r(i)/3.0+r(i+1)/6.0)
        vr(i+1) = vr(i+1) + h*(r(i)/6.0+r(i+1)/3.0)
    end do
    do j = 0, na-1
        h = (phi(j+1)-phi(j))/2.0
        va(j) = va(j)+h
        va(j+1) = va(j+1)+h
    end do
    if (periodic_phi) va(0) = va(0)+va(na)
    do k = 0, size(z)-2
        h = (z(k+1)-z(k))/2.0
        vz(k) = vz(k)+h
        vz(k+1) = vz(k+1)+h
    end do

    ! Validate every denominator before modifying either output.
    ierr = B04_BAD_VOLUME
    do k = 0, size(z)-1
    do j = 0, nj-1
    do i = 0, size(r)-1
        volume = vr(i)*va(j)*vz(k)
        if (.not. ieee_is_finite(volume)) return
        ! The rounded reciprocal limit itself can still overflow on inversion.
        if (volume <= 1.0/huge(volume)) return
    end do
    end do
    end do
    do k = 0, size(z)-1
    do j = 0, nj-1
    do i = 0, size(r)-1
        inv_volume(i,j,k) = 1.0/(vr(i)*va(j)*vz(k))
    end do
    end do
    end do
    phi_measure = va(0:nj-1)
    ierr = B04_OK
end subroutine sub_B04_build_geometry
