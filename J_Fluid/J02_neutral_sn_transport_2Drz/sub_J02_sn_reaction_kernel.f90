!> Common binary-reaction kernels K(g)=sigma(E(g))*g [m^3/s].
!> Depends on cross-section data and reactant kinematics, not distributions or products.
!> A different reaction supplies its own table; its gain/loss physics is handled elsewhere.

    subroutine sub_J02_initialize_reaction_table(energy_ev, cross_section_m2, energy_basis, range_policy, table, ierr)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        real, intent(in) :: energy_ev(:), cross_section_m2(:)
        integer, intent(in) :: energy_basis, range_policy
        type(sn_reaction_table_type), intent(out) :: table
        integer, intent(out) :: ierr
        integer :: n

        ierr = SN_ERR_REACTION_ENERGY_BASIS
        if (energy_basis/=SN_REACTION_ENERGY_CM.and.energy_basis/=SN_REACTION_ENERGY_PROJECTILE_LAB) return
        ierr = SN_ERR_REACTION_POLICY
        if (range_policy/=SN_REACTION_RANGE_ERROR.and.range_policy/=SN_REACTION_RANGE_CLAMP) return
        ierr = SN_ERR_REACTION_TABLE
        n = size(energy_ev)
        if (n<2.or.size(cross_section_m2)/=n) return
        if (.not.all(ieee_is_finite(energy_ev)).or..not.all(ieee_is_finite(cross_section_m2))) return
        if (any(energy_ev<0.0).or.any(cross_section_m2<0.0)) return
        if (any(energy_ev(2:)<=energy_ev(:n-1))) return
        table%energy_ev = energy_ev
        table%cross_section_m2 = cross_section_m2
        table%energy_basis = energy_basis
        table%range_policy = range_policy
        ierr = SN_SUCCESS
    end subroutine sub_J02_initialize_reaction_table

    !> Piecewise-linear interpolation on arbitrary strictly increasing energy nodes.
    !> No implicit extrapolation: ERROR rejects; explicit CLAMP uses endpoint values.
    pure subroutine sub_J02_evaluate_reaction_cross_section(table, energy_ev, cross_section_m2, ierr)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        type(sn_reaction_table_type), intent(in) :: table
        real, intent(in) :: energy_ev
        real, intent(out) :: cross_section_m2
        integer, intent(out) :: ierr
        cross_section_m2 = 0.0
        ierr = SN_ERR_REACTION_INPUT
        if (.not.ieee_is_finite(energy_ev)) return
        if (energy_ev < 0.0) return
        ierr = SN_ERR_REACTION_ENERGY_RANGE
        if (.not.fun_J02_reaction_energy_allowed(table, energy_ev)) return

        cross_section_m2 = fun_J02_interpolate_cross_section(table, energy_ev)
        ierr = SN_SUCCESS
    end subroutine sub_J02_evaluate_reaction_cross_section

    ! Preconditions: initialized table and finite, nonnegative energy.
    pure logical function fun_J02_reaction_energy_allowed(table, energy_ev) result(allowed)
        type(sn_reaction_table_type), intent(in) :: table
        real, intent(in) :: energy_ev

        allowed = table%range_policy == SN_REACTION_RANGE_CLAMP .or. &
            (energy_ev >= table%energy_ev(1) .and. energy_ev <= table%energy_ev(size(table%energy_ev)))
    end function fun_J02_reaction_energy_allowed

    pure real function fun_J02_interpolate_cross_section(table, energy_ev) result(cross_section_m2)
        type(sn_reaction_table_type), intent(in) :: table
        real, intent(in) :: energy_ev
        integer :: lo, hi, mid
        real :: fraction

        lo = 1
        hi = size(table%energy_ev)
        if (energy_ev < table%energy_ev(lo)) then
            cross_section_m2 = table%cross_section_m2(lo)
        else if (energy_ev > table%energy_ev(hi)) then
            cross_section_m2 = table%cross_section_m2(hi)
        else
            do while (hi-lo > 1)
                mid = lo+(hi-lo)/2
                if (energy_ev < table%energy_ev(mid)) then
                    hi = mid
                else
                    lo = mid
                end if
            end do
            fraction = (energy_ev-table%energy_ev(lo))/(table%energy_ev(hi)-table%energy_ev(lo))
            cross_section_m2 = table%cross_section_m2(lo)+fraction* &
                (table%cross_section_m2(hi)-table%cross_section_m2(lo))
        end if
    end function fun_J02_interpolate_cross_section

    !> E_cm=mu*g^2/(2e); E_projectile_lab=m_projectile*g^2/(2e) in the target rest frame.
    !> Caller identifies projectile/target to match the table's energy convention.
    !> Returns energy [eV], microscopic cross section [m^2], and sigma*g [m^3/s].
    !> Outputs are cleared on failure. Finite tabulated sigma gives K=0 at g=0.
    pure subroutine sub_J02_evaluate_reaction_kernel(table, projectile_mass, target_mass, relative_speed, &
        energy_ev, cross_section_m2, kernel, ierr)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        type(sn_reaction_table_type), intent(in) :: table
        real, intent(in) :: projectile_mass, target_mass, relative_speed
        real, intent(out) :: energy_ev, cross_section_m2, kernel
        integer, intent(out) :: ierr
        real :: energy_factor

        energy_ev = 0.0
        cross_section_m2 = 0.0
        kernel = 0.0
        call sub_J02_reaction_energy_factor(table, projectile_mass, target_mass, energy_factor, ierr)
        if (ierr /= SN_SUCCESS) return
        ierr = SN_ERR_REACTION_INPUT
        if (.not.ieee_is_finite(relative_speed)) return
        if (relative_speed < 0.0) return

        call sub_J02_reaction_kernel_at_speed(table, energy_factor, relative_speed, &
            energy_ev, cross_section_m2, kernel, ierr)
    end subroutine sub_J02_evaluate_reaction_kernel

    ! Private calculation after table/masses/speed validation. The energy_factor is reusable
    ! for every velocity pair of the same reaction: sqrt(E[eV]) = energy_factor*g.
    pure subroutine sub_J02_reaction_kernel_at_speed(table, energy_factor, relative_speed, &
        energy_ev, cross_section_m2, kernel, ierr)
        type(sn_reaction_table_type), intent(in) :: table
        real, intent(in) :: energy_factor, relative_speed
        real, intent(out) :: energy_ev, cross_section_m2, kernel
        integer, intent(out) :: ierr
        real :: root_energy, energy_work, cross_section_work

        energy_ev = 0.0
        cross_section_m2 = 0.0
        kernel = 0.0
        ierr = SN_ERR_NUMERIC_RANGE
        if (relative_speed > sqrt(huge(1.0))/energy_factor) return
        root_energy = energy_factor*relative_speed
        energy_work = root_energy*root_energy

        ierr = SN_ERR_REACTION_ENERGY_RANGE
        if (.not.fun_J02_reaction_energy_allowed(table, energy_work)) return
        cross_section_work = fun_J02_interpolate_cross_section(table, energy_work)
        ierr = SN_ERR_NUMERIC_RANGE
        if (cross_section_work > huge(1.0)/max(1.0,relative_speed)) return

        energy_ev = energy_work
        cross_section_m2 = cross_section_work
        kernel = cross_section_work*relative_speed
        ierr = SN_SUCCESS
    end subroutine sub_J02_reaction_kernel_at_speed

    pure subroutine sub_J02_reaction_energy_factor(table, projectile_mass, target_mass, energy_factor, ierr)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        type(sn_reaction_table_type), intent(in) :: table
        real, intent(in) :: projectile_mass, target_mass
        real, intent(out) :: energy_factor
        integer, intent(out) :: ierr
        real, parameter :: elementary_charge = 1.602176634e-19
        real :: mass

        energy_factor = 0.0
        ierr = SN_ERR_REACTION_MASS
        if (.not.all(ieee_is_finite([projectile_mass,target_mass]))) return
        if (projectile_mass<=0.0.or.target_mass<=0.0) return
        mass = projectile_mass
        if (table%energy_basis==SN_REACTION_ENERGY_CM) &
            mass = min(projectile_mass,target_mass)/(1.0+min(projectile_mass,target_mass)/max(projectile_mass,target_mass))
        ierr = SN_ERR_NUMERIC_RANGE
        if (mass<=0.0) return
        energy_factor = sqrt(mass)/sqrt(2.0*elementary_charge)
        ierr = SN_SUCCESS
    end subroutine sub_J02_reaction_energy_factor
