! Nonnegative sharp inlet: exercise the actual directional sweep and its balance.
program test_J02_positivity
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    integer, parameter :: n = 8
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geo
    type(sn_quadrature_type) :: quad
    type(sn_boundary_2drz_type) :: boundary
    real, allocatable :: sigma_all(:,:,:), inlet_all(:,:,:,:), psi_all(:,:,:,:)
    real :: r(n+1), z(n+1), sigma(n,n), bc(4,n,n), psi(3,n,n)
    real :: a(3,3), rhs(3), coeff(3), original(3), mean, balance, incoming, outgoing, removal
    real :: max_balance, minimum_corner
    integer :: j, k, m, ierr, scenario, failures
    logical :: active(n,n), corrected

    failures = 0
    a = 0.0
    a(1,:) = [2.0, 0.5, 0.25]
    rhs = [3.0, 0.0, 0.0]
    coeff = [1.0, 2.0, 0.0]
    call sub_J02_enforce_local_positivity(a, rhs, coeff, ierr, corrected)
    call check(ierr == SN_SUCCESS .and. corrected, 'negative corner triggers P0 recovery')
    call check(maxval(abs(coeff-[1.5, 0.0, 0.0])) < 1.e-13, 'recovery solves the particle balance')
    call check(abs(dot_product(a(1,:),coeff)-rhs(1)) < 1.e-13, 'constant-test balance retained')
    write(*,'(a,4es24.15)') 'VALUE: positivity recovered coefficients/balance error: ', &
        coeff,abs(dot_product(a(1,:),coeff)-rhs(1))
    coeff = [-1.0, 0.0, 0.0]
    call sub_J02_enforce_local_positivity(a, rhs, coeff, ierr)
    call check(ierr == SN_SUCCESS .and. abs(coeff(1)-1.5) < 1.e-13, 'negative mean also recovers')
    original = [2.0, 0.1, -0.2]
    coeff = original
    call sub_J02_enforce_local_positivity(a, rhs, coeff, ierr, corrected)
    call check(ierr == SN_SUCCESS .and. .not. corrected .and. maxval(abs(coeff-original)) < tiny(1.0), &
        'nonnegative P1 coefficients remain unchanged')
    rhs(1) = -1.0
    call sub_J02_enforce_local_positivity(a, rhs, coeff, ierr)
    call check(ierr == SN_ERR_LOCAL_POSITIVITY, 'negative incoming rate is rejected')

    do j = 1, n+1
        r(j) = 1.0+real(j-1)/n
        z(j) = real(j-1)/n
    end do
    active = .true.
    call sub_J02_initialize_mesh(r,z,active,mesh,ierr)
    call check(ierr == SN_SUCCESS, 'mesh construction')
    call sub_J02_build_geometry(mesh,1.0,geo,ierr)
    call check(ierr == SN_SUCCESS, 'geometry construction')
    call sub_J02_build_phase_quadrature(8,1,'midpoint',2.0,quad,ierr)
    call check(ierr == SN_SUCCESS, 'quadrature construction')
    call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
    allocate(sigma_all(n,n,quad%n_dir), inlet_all(4,n,n,quad%n_dir))
    do scenario = 1, 2
        sigma = 0.0
        if (scenario == 2) sigma = 10.0
        inlet_all = 0.0
        do m = 1, quad%n_dir
            sigma_all(:,:,m) = sigma
            if (quad%eta(m) > 0.0) inlet_all(SN_Z_LO,4:5,1,m) = 1.0
        end do
        call sub_J02_sweep(mesh,geo,quad,sigma_all,boundary,psi_all,ierr,boundary_inflow=inlet_all)
        call check(ierr == SN_SUCCESS, 'sharp-inlet sweep succeeds')
        if (ierr /= SN_SUCCESS) error stop 'cannot inspect a failed sweep'
        max_balance = 0.0
        minimum_corner = minval(psi_all(1,:,:,:)-abs(psi_all(2,:,:,:))-abs(psi_all(3,:,:,:)))
        do m = 1, quad%n_dir
            bc = inlet_all(:,:,:,m)
            psi = psi_all(:,:,:,m)
            call check(all(psi(1,:,:) >= abs(psi(2,:,:))+abs(psi(3,:,:))), &
                'all polynomial corners are nonnegative')
            incoming = 0.0
            outgoing = 0.0
            removal = 0.0
            do j = 1, n
                do k = 1, n
                    mean = psi(1,j,k)+geo%xi_bar(j)*psi(2,j,k)
                    removal = removal+sigma(j,k)*geo%volume(j,k)*mean
                end do
                incoming = incoming+max(quad%eta(m),0.0)*geo%area_z_lo(j,1)*bc(SN_Z_LO,j,1)
                if (quad%eta(m) > 0.0) then
                    outgoing = outgoing+quad%eta(m)*geo%area_z_hi(j,n)* &
                        (psi(1,j,n)+geo%xi_bar(j)*psi(2,j,n)+psi(3,j,n))
                else
                    outgoing = outgoing-quad%eta(m)*geo%area_z_lo(j,1)* &
                        (psi(1,j,1)+geo%xi_bar(j)*psi(2,j,1)-psi(3,j,1))
                end if
            end do
            do k = 1, n
                if (quad%mu(m) > 0.0) then
                    outgoing = outgoing+quad%mu(m)*geo%area_r_hi(n,k)*(psi(1,n,k)+psi(2,n,k))
                else
                    outgoing = outgoing-quad%mu(m)*geo%area_r_lo(1,k)*(psi(1,1,k)-psi(2,1,k))
                end if
            end do
            balance = abs(outgoing+removal-incoming)/max(incoming,1.e-30)
            max_balance = max(max_balance,balance)
            call check(balance < 1.e-12, 'boundary outflow plus absorption equals inflow')
        end do
        write(*,'(a,i3,2es24.15)') 'VALUE: sharp inlet scenario/min corner/max relative balance: ', &
            scenario,minimum_corner,max_balance
    end do
    if (failures /= 0) stop 1
    print *, 'RESULT: PASS'
contains
    subroutine check(ok, label)
        logical, intent(in) :: ok
        character(len=*), intent(in) :: label
        if (.not. ok) then
            print *, 'FAIL: ', label
            failures = failures+1
        end if
    end subroutine check
end program test_J02_positivity
