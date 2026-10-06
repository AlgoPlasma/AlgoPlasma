! An exact reduced cylindrical transport field, solved by J02 then consumed by J03.
program test_J02_J03_analytic
    use mod_J02_neutral_sn_transport_2Drz
    use mod_J03_neutral_continuity_faceflux_2Drz
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer :: failed = 0, level
    real :: errors(3)
    do level = 1, 3
        call solve_and_connect(2**(level+1),errors(level))
    end do
    write(*,'(a,3es14.6)') 'SN analytical density errors (4,8,16): ', errors
    call check(errors(2) < 0.7*errors(1) .and. errors(3) < 0.7*errors(2), &
        'SN analytical density converges under spatial refinement')
    call check(errors(3) < 0.03, 'fine-grid SN density is within 3 percent of exact cell means')
    write(*,'(a,i0)') 'n_failed = ', failed
    if (failed /= 0) error stop 1
    write(*,'(a)') 'RESULT: PASS'
contains
    subroutine check(ok,label)
        logical, intent(in) :: ok
        character(len=*), intent(in) :: label
        if (.not. ok) then
            failed = failed+1
            write(*,'(a)') 'FAIL: '//label
        end if
    end subroutine check

    subroutine solve_and_connect(n,error)
        integer, intent(in) :: n
        real, intent(out) :: error
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geom
        type(sn_quadrature_type) :: quad
        type(sn_boundary_2drz_type) :: boundary
        type(sn_transport_result_type) :: result
        type(neutral_transport_closure_2drz_type) :: closure
        real :: re(n+1), ze(n+1), nu(n,n), prescribed(4,n,n,8), exact(n,n)
        real :: area(4,n,n), source(n,n), a, dz, average_z, rc, dt, pin, pout, prod, loss, balance
        real :: max_residual, global_balance, relative_reference_error, reference_inflow
        real, allocatable :: sigma(:,:,:), density(:,:), next(:,:), residual(:,:)
        logical :: active(n,n)
        integer :: ft(4,n,n), i, k, ierr, step
        integer, parameter :: beam = 2
        do i = 1, n+1
            re(i) = 1.0+real(i-1)/n
            ze(i) = real(i-1)/n
        end do
        active = .true.
        call sub_J02_initialize_mesh(re,ze,active,mesh,ierr)
        if (ierr /= SN_SUCCESS) error stop 'analytic mesh failed'
        call sub_J02_build_geometry(mesh,2.0,geom,ierr)
        if (ierr /= SN_SUCCESS) error stop 'analytic geometry failed'
        call sub_J02_initialize_boundary_types(mesh,boundary,ierr)
        if (ierr /= SN_SUCCESS) error stop 'analytic boundary failed'
        call sub_J02_build_phase_quadrature(8,1,'midpoint',4.0,quad,ierr)
        if (ierr /= SN_SUCCESS) error stop 'analytic quadrature failed'
        nu = 1.0
        call sub_J02_build_sigma_from_frequency(quad,nu,sigma,ierr)
        if (ierr /= SN_SUCCESS) error stop 'analytic loss failed'
        ! Only the oblique beam theta=3*pi/8 is populated. No axis direction,
        ! no scattering, and no altered quadrature or production interface.
        ! psi(r,z)=exp(-a*z)/r, a=sigma/eta:
        ! d_r(r*mu*psi)=0 and eta*d_z(psi)+sigma*psi=0.
        a = 0.5/sin(3.0*acos(-1.0)/8.0)
        dz = 1.0/n
        prescribed = 0.0
        do k = 1, n
            average_z = (exp(-a*ze(k))-exp(-a*ze(k+1)))/(a*dz)
            prescribed(SN_R_LO,1,k,beam) = average_z
            do i = 1, n
                rc = 0.5*(re(i)+re(i+1))
                exact(i,k) = quad%weight(beam)*average_z/rc
            end do
        end do
        do i = 1, n
            prescribed(SN_Z_LO,i,1,beam) = 2.0/(re(i)+re(i+1))
        end do
        ! Incoming face constants are exact physical-area means of the
        ! analytical trace. Tangential variation is still approximated.
        call sub_J02_solve_transport(mesh,geom,quad,boundary,sigma,result,ierr, &
            boundary_inflow=prescribed)
        call check(ierr == SN_SUCCESS .and. result%converged, 'analytical open SN solve succeeds')
        if (ierr /= SN_SUCCESS) error stop 'SN analytical solve failed'
        if (.not. all(ieee_is_finite(result%density))) error stop 'nonfinite analytical density'
        error = sqrt(sum(geom%volume*(result%density-exact)**2)/sum(geom%volume*exact**2))
        call check(all(result%density > 0.0), 'analytical SN density is positive')
        call check(maxval(abs(result%velocity_r-2.0*cos(3.0*acos(-1.0)/8.0))) < 1.e-12 .and. &
            maxval(abs(result%velocity_z-2.0*sin(3.0*acos(-1.0)/8.0))) < 1.e-12, &
            'single beam reconstructs the exact two-component velocity')
        area(SN_R_LO,:,:) = geom%area_r_lo
        area(SN_R_HI,:,:) = geom%area_r_hi
        area(SN_Z_LO,:,:) = geom%area_z_lo
        area(SN_Z_HI,:,:) = geom%area_z_hi
        ft(SN_R_LO,:,:) = boundary%face_r_lo
        ft(SN_R_HI,:,:) = boundary%face_r_hi
        ft(SN_Z_LO,:,:) = boundary%face_z_lo
        ft(SN_Z_HI,:,:) = boundary%face_z_hi
        source = 0.0
        ! Transfer actual reconstructed arrays. Never rebuild fluxes as n*u.
        call sub_J03_initialize_transport_closure(active,ft,geom%volume,area,result%density, &
            result%flux_r,result%flux_z,result%inflow_flux,result%outflow_flux,nu,1.e-12,closure,ierr)
        if (ierr /= J03_SUCCESS) error stop 'J02 reference rejected by J03'
        call sub_J03_compute_residual(closure,result%density,source,residual,max_residual,global_balance,ierr)
        if (ierr /= J03_SUCCESS) error stop 'SN-to-J03 reference residual failed'
        call check(max_residual/maxval(exact) < 1.e-10, 'J02 reference satisfies each J03 cell balance')
        call sub_J03_compute_balance(closure,result%density,source,pin,pout,prod,loss,balance,ierr)
        if (ierr /= J03_SUCCESS) error stop 'SN-to-J03 balance failed'
        reference_inflow = pin
        write(*,'(a,i3,5es24.15)') 'VALUE: analytic grid/incoming/outgoing/loss/scaled balance/scaled cell residual: ', &
            n,pin,pout,loss,balance,max_residual/maxval(exact)
        call check(balance < 1.e-11, 'SN open escape plus volume loss equals injection')
        ! Start empty: testing only a step at the reference would be insufficient.
        call sub_J03_compute_stable_timestep(closure,0.7,dt,ierr)
        if (ierr /= J03_SUCCESS) error stop 'SN-to-J03 timestep failed'
        allocate(density(n,n))
        density = 0.0
        do step = 1, 2000
            call sub_J03_continuity_step(closure,density,source,dt,.false.,next,ierr)
            if (ierr /= J03_SUCCESS) error stop 'SN-to-J03 filling step failed'
            if (any(next < 0.0)) error stop 'negative SN-to-J03 density'
            call move_alloc(next,density)
        end do
        relative_reference_error = maxval(abs(density-result%density))/maxval(result%density)
        write(*,'(a,i0,a,2es24.15)') 'grid=', n, ' SN exact L2 / J03 reference max: ', &
            error, relative_reference_error
        call check(relative_reference_error < 1.e-9, 'J03 fills from zero to the actual SN reference')
        call sub_J03_compute_balance(closure,density,source,pin,pout,prod,loss,balance,ierr)
        if (ierr /= J03_SUCCESS) error stop 'SN-to-J03 final balance failed'
        call check(abs(pin-reference_inflow) < 1.e-12 .and. balance < 1.e-9, &
            'filled J03 solution preserves injection and global particle balance')
        write(*,'(a,i3,3es24.15)') 'VALUE: filled grid/timestep/scaled balance/inlet difference: ', &
            n,dt,balance,abs(pin-reference_inflow)
    end subroutine solve_and_connect
end program test_J02_J03_analytic
