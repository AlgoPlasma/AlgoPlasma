!> @brief Deposit one particle's represented number or charge into nodal density
!> using linear CIC weights on a three-dimensional structured tensor-product
!> cylindrical (r, phi, z) grid. Each coordinate direction allows nonuniform spacing.
!> @author Xin Luo (2026/10/31)
!>
!> @details
!> Grid nodes are formed by all combinations of r(i), phi(j), z(k);
!> regular (i,j,k) indices determine cells and adjacent nodes.
!>
!> For the caller-supplied cell and particle position, the routine forms
!> one-dimensional linear weights in r, phi and z. Their tensor product
!> gives the eight local vertex weights. Each nodal density increment is
!> @f[
!> \Delta D=\mathrm{amount}\,w_r w_\phi w_z\,\mathrm{inv\_volume},
!> @f]
!> where w_r, w_phi and w_z are the corresponding one-dimensional weights.
!> inv_volume contains the inverse effective cylindrical nodal volumes from
!> sub_B04_build_geometry for the same grid and periodic configuration.
!>
!> For periodic phi, weights are computed on the unwrapped last cell
!> before its upper angular node is mapped to node zero.
!> The caller supplies a valid position and containing cell, and initializes
!> density before a new deposition stage. Each call adds one particle's
!> contribution. For a full-circle r=0 axis, collect shared-node contributions
!> before applying axis averaging.
!>
!> @param[in] r Finite, strictly increasing radial nodes r(0:nr), with nr>=1 and
!> r(0)>=0. Retain the physical distance from the cylindrical axis; r(0)>0
!> describes an annulus. Length units must agree with z and position.
!> @param[in] phi Finite, strictly increasing angular nodes phi(0:nphi), in radians,
!> with nphi>=1. Keep the upper endpoint even when density uses periodic indexing.
!> @param[in] z Finite, strictly increasing axial nodes z(0:nz), with nz>=1,
!> including both physical endpoints. The origin may be shifted.
!> @param[in] periodic_phi If true, identify the last angular endpoint with the first
!> and store nphi independent angular nodes; if false, store nphi+1 angular nodes.
!> @param[in] cell Integer array (3): zero-based (i,j,k) cell indices, respectively
!> in 0:nr-1, 0:nphi-1, 0:nz-1. The caller performs the cell search.
!> @param[in] position Real array (3): physical (radius, azimuth in radians, axial
!> position), inside the supplied cell's three closed coordinate intervals.
!> @param[in] amount Finite per-particle contribution: wp for represented particle
!> number, or qp*wp for represented charge. wp is the macroparticle's particle count;
!> qp is the signed charge of one real particle. wp may vary between particles.
!> @param[in] inv_volume Positive finite inverse effective nodal volumes from the
!> same grid and periodic configuration, with the same shape as density.
!> @param[inout] density Nodal density accumulated in place. Its index layout is
!> (0:nr,0:nphi-1,0:nz) for periodic phi, or (0:nr,0:nphi,0:nz) otherwise. Initialize
!> it before the first accumulation. With lengths in metres and charge in coulombs,
!> number density is in m^-3 and charge density is in C m^-3; normalized calculations
!> require consistent coordinate and amount scales.
!> @param[out] ierr B04 status; see @ref b04_return_status "module return-status definitions".
!> Checks cover array sizes, the supplied cell, local geometry and particle data,
!> accessed nodal values, the eight computed increments and the range of density sums.
!>
!> @note nr, nphi and nz denote cell counts inferred from coordinate array lengths.
!> Actual Fortran arrays may have other lower bounds: their first elements map to
!> dummy index zero, and cell uses that same relative indexing.
!> @note Complete coordinate validation belongs to geometry preparation; this
!> per-particle routine checks local geometry and accessed entries. A nonzero status
!> returned by these checks leaves density unchanged. Final additions are range-checked
!> in temporary values before writing density. Keep intermediate products within the
!> selected floating-point range; exception handling follows the compiler configuration.
!> @note This routine is exported through mod_B04_scatter_3d_raz_nonuniform.
!> Compile the module and caller with the same default real kind.
!> @note Concurrent calls require separate density buffers or caller synchronization.
!> @see @ref sub_b04_build_geometry "sub_B04_build_geometry",
!> @ref sub_b04_average_axis "sub_B04_average_axis",
!> @ref sub_b04_project_density "sub_B04_project_density"
subroutine sub_B04_scatter_3d_raz_nonuniform(r, phi, z, periodic_phi, &
        cell, position, amount, inv_volume, density, ierr)

    real, intent(in) :: r(0:), phi(0:), z(0:), position(3), amount
    logical, intent(in) :: periodic_phi
    integer, intent(in) :: cell(3)
    real, intent(in) :: inv_volume(0:,0:,0:)
    real, intent(inout) :: density(0:,0:,0:)
    integer, intent(out) :: ierr
    integer :: nc(3), nj, ix(0:1), iy(0:1), iz(0:1), a, b, c, node_b
    real :: lo(3), hi(3), h(3), fraction(3), weights(0:1,3), delta(0:1,0:1,0:1)
    real :: trial_density(0:1,0:1,0:1), old_value, increment

    nc = [size(r)-1,size(phi)-1,size(z)-1]
    ierr = B04_BAD_GRID
    if (any(nc < 1)) return
    nj = nc(2)+1
    if (periodic_phi) nj = nc(2)
    ierr = B04_BAD_SHAPE
    if (any(shape(density) /= [nc(1)+1,nj,nc(3)+1])) return
    if (any(shape(inv_volume) /= shape(density))) return
    ierr = B04_BAD_CELL
    if (any(cell < 0) .or. any(cell >= nc)) return

    lo = [r(cell(1)),phi(cell(2)),z(cell(3))]
    hi = [r(cell(1)+1),phi(cell(2)+1),z(cell(3)+1)]
    ierr = B04_BAD_GRID
    if (.not. all(ieee_is_finite(lo))) return
    if (.not. all(ieee_is_finite(hi))) return
    if (any(hi <= lo) .or. lo(1) < 0.0) return
    h = hi-lo
    if (.not. all(ieee_is_finite(h))) return
    ierr = B04_BAD_VALUE
    if (.not. all(ieee_is_finite(position))) return
    if (.not. ieee_is_finite(amount)) return
    if (any(position < lo) .or. any(position > hi)) return
    fraction = (position-lo)/h
    weights(0,:) = 1.0-fraction
    weights(1,:) = fraction
    ix = [cell(1),cell(1)+1]
    iy = [cell(2),cell(2)+1]
    iz = [cell(3),cell(3)+1]
    if (periodic_phi) iy(1) = modulo(iy(1),nc(2))

    do c = 0, 1
    do b = 0, 1
    do a = 0, 1
        ierr = B04_BAD_VOLUME
        if (.not. ieee_is_finite(inv_volume(ix(a),iy(b),iz(c)))) return
        if (inv_volume(ix(a),iy(b),iz(c)) <= 0.0) return
        ierr = B04_BAD_VALUE
        trial_density(a,b,c) = density(ix(a),iy(b),iz(c))
        if (.not. ieee_is_finite(trial_density(a,b,c))) return
        delta(a,b,c) = amount*weights(a,1)*weights(b,2)*weights(c,3)*inv_volume(ix(a),iy(b),iz(c))
        if (.not. ieee_is_finite(delta(a,b,c))) return
    end do
    end do
    end do
    ! Stage additions in their original order, sharing a temporary for repeated targets.
    ierr = B04_BAD_VALUE
    do c = 0, 1
    do b = 0, 1
        node_b = b
        if (iy(0) == iy(1)) node_b = 0
    do a = 0, 1
        old_value = trial_density(a,node_b,c)
        increment = delta(a,b,c)
        if ((old_value > 0.0 .and. increment > 0.0) .or. &
            (old_value < 0.0 .and. increment < 0.0)) then
            ! Subtract the larger magnitude to avoid rounding the overflow bound upward.
            if (min(abs(old_value),abs(increment)) > &
                huge(old_value)-max(abs(old_value),abs(increment))) return
        end if
        trial_density(a,node_b,c) = old_value+increment
    end do
    end do
    end do
    ! Commit each destination once, after every staged sum has passed.
    do c = 0, 1
    do b = 0, 1
        if (b == 1 .and. iy(0) == iy(1)) cycle
    do a = 0, 1
        density(ix(a),iy(b),iz(c)) = trial_density(a,b,c)
    end do
    end do
    end do
    ierr = B04_OK
end subroutine sub_B04_scatter_3d_raz_nonuniform
