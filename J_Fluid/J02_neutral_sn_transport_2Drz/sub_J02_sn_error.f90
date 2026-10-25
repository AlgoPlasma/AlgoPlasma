!> Human-readable diagnostics for the globally unique J02 status codes.

    function fun_J02_error_message(ierr) result(message)
        integer, intent(in) :: ierr
        character(len = 160) :: message

        select case (ierr)
          case (SN_SUCCESS)
            message = 'success'
          case (SN_ERR_MESH_EDGE_COUNT)
            message = 'r_edge and z_edge must each contain at least two entries'
          case (SN_ERR_MESH_ACTIVE_SHAPE)
            message = 'active must have shape (size(r_edge)-1,size(z_edge)-1)'
          case (SN_ERR_MESH_NEGATIVE_RADIUS)
            message = 'the first radial edge must be nonnegative'
          case (SN_ERR_MESH_RADIAL_ORDER)
            message = 'radial edges must be strictly increasing'
          case (SN_ERR_MESH_AXIAL_ORDER)
            message = 'axial edges must be strictly increasing'
          case (SN_ERR_GEOMETRY_MESH)
            message = 'mesh arrays are unallocated or inconsistent with mesh dimensions'
          case (SN_ERR_GEOMETRY_THETA_SPAN)
            message = 'theta_span must be positive'
          case (SN_ERR_ANGLE_COUNT)
            message = 'n_angles must be at least 8 and divisible by 4'
          case (SN_ERR_ANGLE_SCHEME)
            message = 'angular scheme must be midpoint or gauss-chebyshev (an alias)'
          case (SN_ERR_SPEED_COUNT)
            message = 'n_speeds must be at least 1'
          case (SN_ERR_SPEED_MAX)
            message = 'speed_max must be finite and positive'
          case (SN_ERR_SPEED_EDGES)
            message = 'speed edges must contain at least two finite entries, start at zero and strictly increase'
          case (SN_ERR_SPEED_RANGE)
            message = 'speed intervals must produce representable, strictly positive nodes and weights'
          case (SN_ERR_QUADRATURE_LAYOUT)
            message = 'velocity directions must be finite'
          case (SN_ERR_SIGMA_FREQUENCY_SHAPE)
            message = 'frequency must have shape (nr,nz)'
          case (SN_ERR_SIGMA_NEGATIVE_FREQUENCY)
            message = 'frequency must be nonnegative'
          case (SN_ERR_SOURCE_TEMPERATURE)
            message = 'temperature must be positive'
          case (SN_ERR_SOURCE_MASS)
            message = 'particle_mass must be positive'
          case (SN_ERR_SOURCE_INPUT_SHAPE)
            message = 'source input array size must equal quadrature%n_dir'
          case (SN_ERR_SOURCE_NORMAL)
            message = 'boundary normal must have unit length'
          case (SN_ERR_SOURCE_NEGATIVE_DATA)
            message = 'source shape or crossing probabilities must be nonnegative'
          case (SN_ERR_SOURCE_ZERO_DATA)
            message = 'incoming MC crossing probabilities must have positive total mass'
          case (SN_ERR_SOURCE_TARGET_FLUX)
            message = 'target_flux must be nonnegative'
          case (SN_ERR_SOURCE_ZERO_NORMALIZATION)
            message = 'incoming source normalization is zero on this quadrature'
          case (SN_ERR_SOURCE_OUTGOING_DATA)
            message = 'MC crossing probabilities may be nonzero only for incoming directions'
          case (SN_ERR_LOCAL_SINGULAR)
            message = 'local 3-by-3 system is singular to working precision'
          case (SN_ERR_SWEEP_AXIS_DIRECTION)
            message = 'axis-aligned ordinates are unsupported: both mu and eta must be nonzero'
          case (SN_ERR_SWEEP_LOCAL_SOLVE)
            message = 'local P1-DG solve failed; inspect failed_direction, failed_i, failed_k'
          case (SN_ERR_SWEEP_NEGATIVE_SIGMA)
            message = 'sigma_t must be nonnegative'
          case (SN_ERR_SWEEP_FACE_TOPOLOGY)
            message = 'face type is invalid, or REMOTE faces were supplied without a partition'
          case (SN_ERR_REFLECTION_INPUT)
            message = 'invalid inlet selection, wall state, partial interval, diffuse fraction, or progress interval'
          case (SN_ERR_WALL_NORMALIZATION)
            message = 'wall Maxwell distribution cannot be normalized; check wall temperature and velocity grid'
          case (SN_ERR_SOURCE_ITERATION_OPTIONS)
            message = 'source iteration requires finite positive tolerance, max_iterations >= 2, and nonnegative progress interval'
          case (SN_ERR_SOURCE_ITERATION_NOT_CONVERGED)
            message = 'reflecting-boundary source iteration reached max_iterations'
          case (SN_ERR_PARTIAL_INLET)
            message = 'partial z-low inlet intervals must satisfy -1 <= xi_lo <= xi_hi <= 1'
          case (SN_ERR_LOCAL_POSITIVITY)
            message = 'positivity recovery failed: nonfinite data, nonpositive diagonal, or negative incoming rate'
          case (SN_ERR_MPI_DISABLED)
            message = 'MPI partition supplied to a build without -DJ02_USE_MPI'
          case (SN_ERR_MPI_LAYOUT)
            message = 'MPI requires a matching nonperiodic 2D Cartesian tiling, local mesh, and REMOTE interfaces'
          case (SN_ERR_MPI_INPUT)
            message = 'MPI ranks disagree on quadrature/iteration options, or a partial inlet is not at global z-low'
          case (SN_ERR_MPI_THREAD)
            message = 'call J02 on the MPI main thread; hybrid builds require MPI_THREAD_FUNNELED or higher'
          case (SN_ERR_REACTION_TABLE)
            message = 'reaction table requires matching arrays of at least two finite, increasing nonnegative ' // &
                'energies and nonnegative cross sections'
          case (SN_ERR_REACTION_POLICY)
            message = 'reaction out-of-range policy must explicitly be ERROR or CLAMP'
          case (SN_ERR_REACTION_ENERGY_BASIS)
            message = 'reaction energy basis must explicitly be CM relative energy or PROJECTILE_LAB incident energy'
          case (SN_ERR_REACTION_MASS)
            message = 'reaction projectile and target masses must be finite and positive'
          case (SN_ERR_REACTION_INPUT)
            message = 'reaction speed or energy must be finite and nonnegative'
          case (SN_ERR_REACTION_ENERGY_RANGE)
            message = 'reaction energy is outside the tabulated range under the ERROR policy'
          case (SN_ERR_NUMERIC_RANGE)
            message = 'calculation exceeds the representable numeric range'
          case (SN_ERR_CEX_BACKGROUND)
            message = 'ion background requires finite nonnegative density/distribution, positive ' // &
                'temperature and mass, and finite drifts'
          case (SN_ERR_CEX_BACKGROUND_SHAPE)
            message = 'ion_distribution size must match the ion quadrature node count'
          case (SN_ERR_CEX_NORMALIZATION)
            message = 'ion Maxwellian has zero discrete support; check the velocity grid'
          case default
            write(message, '(a,i0)') 'unknown J02 error code: ', ierr
        end select
    end function fun_J02_error_message
