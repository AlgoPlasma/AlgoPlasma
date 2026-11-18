! Deterministic kinematics tests; no cross sections, distributions or CEX operator.
program test_J02_relative_speed
    use mod_J02_neutral_sn_transport_2Drz
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
!$  use omp_lib, only: omp_get_num_threads
    implicit none
    type(sn_quadrature_type) :: neutral, ion
    real, allocatable :: vn(:,:), vi(:,:), pair_speed(:,:)
    real :: pi, tol, zero(3), a(3), b(3), ax(3), bx(3), phi, expected, actual
    real :: alpha, beta, scale, big, small, adjacent, max_pair_error, max_rotation_error
    integer :: ierr, m, j, q, opposite, checks, workers, unit
    character(len=1024) :: csv_path

    pi = acos(-1.0)
    tol = 200.0*epsilon(1.0)
    zero = 0.0
    checks = 0
    max_pair_error = 0.0
    max_rotation_error = 0.0
    workers = 1
!$omp parallel default(none) shared(workers)
!$omp single
!$  workers = omp_get_num_threads()
!$omp end single
!$omp end parallel

    a = [300.0,0.0,400.0]
    call check(fun_J02_relative_speed(a,a),0.0,500.0,'identical velocities')
    call check(fun_J02_relative_speed(zero,zero),0.0,1.0,'both velocities zero')
    call check(fun_J02_relative_speed(a,zero),500.0,500.0,'3-4-5 stationary target')
    call check(fun_J02_relative_speed(a,-a),1000.0,1000.0,'opposite velocities')
    call check(fun_J02_relative_speed([500.0,0.0,0.0],[0.0,0.0,500.0]), &
        500.0*sqrt(2.0),500.0,'orthogonal equal speeds')
    call check(fun_J02_relative_speed([0.0,300.0,0.0],[0.0,-100.0,0.0]), &
        400.0,400.0,'nonzero azimuthal component in generic helper')

    ! Independent known rotations also detect using the SN angle as a space angle.
    a = [3.0,4.0,5.0]
    ax = fun_J02_velocity_cyl_to_cart(a,0.0)
    call require(maxval(abs(ax-a)) < tol,'zero azimuth conversion')
    ax = fun_J02_velocity_cyl_to_cart(a,0.5*pi)
    call require(maxval(abs(ax-[-4.0,3.0,5.0])) < 5.0*tol,'quarter-turn conversion')
    a = [300.0,-125.0,400.0]
    b = [-100.0,75.0,50.0]
    expected = sqrt(400.0**2+200.0**2+350.0**2)
    do q=-8,8
        phi = real(q)*pi/7.0
        ax = fun_J02_velocity_cyl_to_cart(a,phi)
        bx = fun_J02_velocity_cyl_to_cart(b,phi)
        actual = fun_J02_relative_speed(ax,bx)
        call check(actual,expected,expected,'common rotation preserves relative speed')
        call check(fun_J02_relative_speed(ax,zero),sqrt(sum(a*a)), &
            sqrt(sum(a*a)),'rotation preserves individual speed')
        max_rotation_error = max(max_rotation_error,abs(actual-expected)/expected)
    end do
    ax = fun_J02_velocity_cyl_to_cart([500.0,0.0,0.0],0.0)
    bx = fun_J02_velocity_cyl_to_cart([500.0,0.0,0.0],0.5*pi)
    call check(fun_J02_relative_speed(ax,bx),500.0*sqrt(2.0),500.0, &
        'different local bases must be converted before subtraction')

    ! Relative speed should remain accurate without overflow-prone squared speeds.
    big = 4.0*sqrt(huge(1.0))
    small = 64.0*tiny(1.0)
    call check(fun_J02_relative_speed([3.0*big,4.0*big,0.0],zero), &
        5.0*big,5.0*big,'large representable norm')
    call check(fun_J02_relative_speed([3.0*small,4.0*small,0.0],zero), &
        5.0*small,5.0*small,'small representable norm')
    adjacent = nearest(big,1.0)
    call check(fun_J02_relative_speed([big,0.0,0.0],[adjacent,0.0,0.0]), &
        adjacent-big,adjacent-big,'nearby large velocities')

    ! Unequal nonuniform velocity grids: 80 neutral nodes and 24 ion nodes.
    call sub_J02_build_phase_quadrature_from_edges(16, &
        [0.0,125.0,500.0,1000.0,2000.0,4000.0],'midpoint',neutral,ierr)
    call require(ierr==SN_SUCCESS,'neutral quadrature')
    call sub_J02_build_phase_quadrature_from_edges(8, &
        [0.0,250.0,1500.0,5000.0],'midpoint',ion,ierr)
    call require(ierr==SN_SUCCESS,'ion quadrature')
    call sub_J02_build_velocity_vectors(neutral,vn,ierr)
    call require(ierr==SN_SUCCESS,'neutral velocity vectors')
    call require(size(vn,1)==3.and.size(vn,2)==80,'neutral vector layout')
    call require(maxval(abs(vn(2,:)))<=0.0,'J02 has zero azimuthal velocity')
    call sub_J02_build_velocity_vectors(ion,vi,ierr)
    call require(ierr==SN_SUCCESS,'ion velocity vectors')
    call require(size(vi,1)==3.and.size(vi,2)==24,'ion vector layout')
    do m=1,neutral%n_dir
        alpha = 2.0*pi*(real(mod(m-1,16))+0.5)/16.0
        expected = neutral%speed(m)
        call check(vn(1,m),expected*cos(alpha),expected,'neutral radial component and ordering')
        call check(vn(3,m),expected*sin(alpha),expected,'neutral axial component and ordering')
        call check(fun_J02_relative_speed(vn(:,m),zero),expected,expected,'node speed reconstruction')
        call check(fun_J02_relative_speed(vn(:,m),vn(:,m)),0.0,expected,'zero diagonal')
        opposite = ((m-1)/16)*16+mod(mod(m-1,16)+8,16)+1
        call check(fun_J02_relative_speed(vn(:,m),vn(:,opposite)), &
            2.0*expected,2.0*expected,'opposite node in same speed group')
    end do
    do j=1,ion%n_dir
        beta = 2.0*pi*(real(mod(j-1,8))+0.5)/8.0
        call check(vi(1,j),ion%speed(j)*cos(beta),ion%speed(j),'ion radial component and ordering')
        call check(vi(3,j),ion%speed(j)*sin(beta),ion%speed(j),'ion axial component and ordering')
    end do

    allocate(pair_speed(neutral%n_dir,ion%n_dir))
!$omp parallel do collapse(2) default(none) shared(vn,vi,pair_speed,neutral,ion) private(m,j)
    do j=1,ion%n_dir
        do m=1,neutral%n_dir
            pair_speed(m,j) = fun_J02_relative_speed(vn(:,m),vi(:,j))
        end do
    end do
!$omp end parallel do
    call get_command_argument(1,csv_path)
    if (len_trim(csv_path)>0) then
        open(newunit=unit,file=trim(csv_path),status='replace',action='write')
        write(unit,'(a)') 'neutral_node,ion_node,relative_speed,cosine_law_reference,cartesian_speed'
    end if
    do j=1,ion%n_dir
        beta = 2.0*pi*(real(mod(j-1,8))+0.5)/8.0
        do m=1,neutral%n_dir
            alpha = 2.0*pi*(real(mod(m-1,16))+0.5)/16.0
            scale = max(neutral%speed(m),ion%speed(j))
            ! Independent law-of-cosines reference at moderate physical speeds.
            expected = sqrt(neutral%speed(m)**2+ion%speed(j)**2 &
                -2.0*neutral%speed(m)*ion%speed(j)*cos(alpha-beta))
            actual = pair_speed(m,j)
            call require(ieee_is_finite(actual).and.actual>=0.0,'finite nonnegative pair speed')
            call check(actual,expected,scale,'independent law of cosines')
            call check(fun_J02_relative_speed(vi(:,j),vn(:,m)),actual,scale,'exchange symmetry')
            call check(fun_J02_relative_speed(vn(:,m),vi(:,j)),actual,scale,'repeat pair is unchanged')
            phi = 0.37
            ax = fun_J02_velocity_cyl_to_cart(vn(:,m),phi)
            bx = fun_J02_velocity_cyl_to_cart(vi(:,j),phi)
            call check(fun_J02_relative_speed(ax,bx),actual,scale,'local and Cartesian node-pair agreement')
            max_pair_error = max(max_pair_error,abs(actual-expected)/scale)
            max_rotation_error = max(max_rotation_error,abs(fun_J02_relative_speed(ax,bx)-actual)/scale)
            if (len_trim(csv_path)>0) write(unit,'(i0,a,i0,3(a,es26.17e3))') &
                m,',',j,',',actual,',',expected,',',fun_J02_relative_speed(ax,bx)
        end do
    end do
    if (len_trim(csv_path)>0) close(unit)

    ! Node reconstruction consumes initialized quadratures; malformed-object
    ! rejection belongs to the constructors, not this arithmetic helper.

    write(*,'(a,i0)') 'INFO: real bytes: ',storage_size(1.0)/8
    write(*,'(a,i0)') 'INFO: OpenMP workers: ',workers
    write(*,'(a,i0)') 'VALUE: assertions: ',checks
    write(*,'(a,i0)') 'VALUE: velocity pairs: ',size(pair_speed)
    write(*,'(a,es24.15)') 'VALUE: maximum cosine-law scaled error: ',max_pair_error
    write(*,'(a,es24.15)') 'VALUE: maximum rotation scaled error: ',max_rotation_error
    print *, 'RESULT: PASS'
contains
    subroutine require(condition,label)
        logical, intent(in) :: condition
        character(len=*), intent(in) :: label
        checks = checks+1
        if (.not.condition) then
            print *, 'FAIL: ',label
            error stop 1
        end if
    end subroutine require
    subroutine check(actual_value,expected_value,error_scale,label)
        real, intent(in) :: actual_value,expected_value,error_scale
        character(len=*), intent(in) :: label
        call require(ieee_is_finite(actual_value),label//' is finite')
        call require(abs(actual_value-expected_value)/error_scale<=tol,label)
    end subroutine check
end program test_J02_relative_speed
