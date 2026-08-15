program test_3d_cartesian_wavepacket_cpml
    use mod_E03_cpml_3d_cartesian
    use mod_E03_fdtd_3d_cartesian

    implicit none

    integer, parameter :: dp = kind(1.0)

    real(dp), parameter :: pi = 3.1415926535897932384626433832795d0
    real(dp), parameter :: c0 = 2.99792458d8
    real(dp), parameter :: mu0 = 4.0d0*pi*1.0d-7
    real(dp), parameter :: eps0 = 1.0d0/(mu0*c0*c0)
    real(dp), parameter :: eta0 = sqrt(mu0/eps0)

    integer, parameter :: n_trans_interior = 8
    integer, parameter :: npml_ref = 20

    integer :: n_long_interior = 136
    integer :: ref_extra = 200
    integer :: nstep = 450
    integer :: late_gate = 260

    real(dp), parameter :: dx = 1.0d-3
    real(dp), parameter :: dy = 1.0d-3
    real(dp), parameter :: dz = 1.0d-3
    real(dp), parameter :: dt = 0.99d0/(c0*sqrt(1.0d0/dx**2 + 1.0d0/dy**2 + 1.0d0/dz**2))

    real(dp), parameter :: trans_min_interior = -0.004d0
    real(dp), parameter :: packet_amp = 1.0d0

    real(dp) :: long_min_interior = -0.068d0
    real(dp) :: packet_margin = 36.0d-3
    real(dp) :: probe_margin = 24.0d-3

    integer :: npml = 12
    real(dp) :: lambda0 = 12.0d-3
    real(dp) :: sigma_long = 18.0d-3
    real(dp) :: pml_m = 3.5d0
    real(dp) :: pml_R0 = 1.0d-6
    real(dp) :: kappa_max = 8.0d0
    real(dp) :: alpha_max = 0.0d0
    character(len=16) :: case_filter = 'all'

    character(len=16), dimension(6), parameter :: cases = (/ &
        'x_plus          ', 'x_minus         ', 'y_plus          ', &
        'y_minus         ', 'z_plus          ', 'z_minus         ' /)

    call parse_args()
    call write_case_info()
    call run_all_cases()

contains

    subroutine parse_args()
        implicit none

        character(len=64) :: arg
        integer :: stat
        integer :: int_value
        real(dp) :: value_mm

        call get_command_argument(1, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) value_mm
            if (value_mm <= 0.0d0) stop 'ERROR: lambda_mm must be positive.'
            lambda0 = value_mm*1.0d-3
        end if

        call get_command_argument(2, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) npml
            if (npml < 2 .or. npml > 40) stop 'ERROR: npml must be in [2, 40].'
        end if

        call get_command_argument(3, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) read(arg,*) kappa_max

        call get_command_argument(4, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) read(arg,*) alpha_max

        call get_command_argument(5, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) read(arg,*) pml_m

        call get_command_argument(6, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) read(arg,*) pml_R0

        call get_command_argument(7, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) case_filter = trim(arg)

        call get_command_argument(8, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) value_mm
            if (value_mm <= 0.0d0) stop 'ERROR: sigma_long_mm must be positive.'
            sigma_long = value_mm*1.0d-3
        end if

        call get_command_argument(9, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 32) stop 'ERROR: n_long_interior must be at least 32.'
            n_long_interior = int_value
        end if

        call get_command_argument(10, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) value_mm
            if (value_mm <= 0.0d0) stop 'ERROR: packet_margin_mm must be positive.'
            packet_margin = value_mm*1.0d-3
            probe_margin = max(dx, packet_margin - lambda0)
        end if

        call get_command_argument(11, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 1) stop 'ERROR: nstep must be positive.'
            nstep = int_value
        end if

        call get_command_argument(12, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) stop 'ERROR: late_gate must be non-negative.'
            late_gate = int_value
        end if

        call get_command_argument(13, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) stop 'ERROR: ref_extra must be non-negative.'
            ref_extra = int_value
        end if

        call update_derived_setup()
    end subroutine parse_args


    subroutine update_derived_setup()
        implicit none

        long_min_interior = -0.5d0*real(n_long_interior,dp)*dx
        if (late_gate > nstep) late_gate = nstep
        if (probe_margin >= packet_margin) stop 'ERROR: probe_margin must be smaller than packet_margin.'
        if (2.0d0*packet_margin >= real(n_long_interior,dp)*dx) &
            stop 'ERROR: packet_margin is too large for n_long_interior.'
    end subroutine update_derived_setup


    subroutine run_all_cases()
        implicit none

        integer :: icase, unit_id
        integer :: nx, ny, nz, nrx, nry, nrz
        real(dp) :: xmin, ymin, zmin, rxmin, rymin, rzmin
        real(dp), allocatable :: probe_cpml(:), probe_ref(:), err_db(:)
        real(dp) :: e0, e1, late_error_db, final_energy_db, ref_norm
        character(len=16) :: cname

        allocate(probe_cpml(0:nstep), probe_ref(0:nstep), err_db(0:nstep))

        open(newunit=unit_id, file='metrics.dat', status='replace', action='write')
        write(unit_id,'(A)') 'case,late_gate_step,late_reflection_error_db,final_interior_energy_db,max_abs_ref_probe'

        do icase = 1, size(cases)
            cname = trim(cases(icase))
            if (trim(case_filter) /= 'all' .and. trim(case_filter) /= trim(cname)) cycle
            write(*,'(A,A)') 'Running case: ', trim(cname)

            call compact_geometry(cname, nx, ny, nz, xmin, ymin, zmin)
            call reference_geometry(cname, nrx, nry, nrz, rxmin, rymin, rzmin)
            call run_one_sim(cname, nx, ny, nz, npml, xmin, ymin, zmin, .true., probe_cpml, e0, e1)
            call run_one_sim(cname, nrx, nry, nrz, npml_ref, rxmin, rymin, rzmin, .false., probe_ref, e0, e1)

            ref_norm = max(maxval(abs(probe_ref)), 1.0d-300)
            err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
            late_error_db = maxval(err_db(late_gate:nstep))

            call run_one_sim(cname, nx, ny, nz, npml, xmin, ymin, zmin, .false., probe_cpml, e0, e1)
            final_energy_db = 10.0d0*log10(max(e1, 1.0d-300)/max(e0, 1.0d-300))

            write(unit_id,'(A,",",I0,",",ES16.8,",",ES16.8,",",ES16.8)') &
                trim(cname), late_gate, late_error_db, final_energy_db, ref_norm
            call write_probe(trim(cname)//'_probe.dat', probe_cpml, probe_ref, err_db)
        end do

        close(unit_id)
        deallocate(probe_cpml, probe_ref, err_db)
    end subroutine run_all_cases


    subroutine compact_geometry(cname, nx, ny, nz, xmin, ymin, zmin)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(out) :: nx, ny, nz
        real(dp), intent(out) :: xmin, ymin, zmin

        nx = n_trans_interior
        ny = n_trans_interior
        nz = n_trans_interior
        xmin = trans_min_interior
        ymin = trans_min_interior
        zmin = trans_min_interior

        if (index(cname, 'x_') == 1) then
            nx = n_long_interior + 2*npml
            xmin = long_min_interior - real(npml,dp)*dx
        else if (index(cname, 'y_') == 1) then
            ny = n_long_interior + 2*npml
            ymin = long_min_interior - real(npml,dp)*dy
        else
            nz = n_long_interior + 2*npml
            zmin = long_min_interior - real(npml,dp)*dz
        end if
    end subroutine compact_geometry


    subroutine reference_geometry(cname, nx, ny, nz, xmin, ymin, zmin)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(out) :: nx, ny, nz
        real(dp), intent(out) :: xmin, ymin, zmin

        nx = n_trans_interior
        ny = n_trans_interior
        nz = n_trans_interior
        xmin = trans_min_interior
        ymin = trans_min_interior
        zmin = trans_min_interior

        if (index(cname, 'x_') == 1) then
            nx = n_long_interior + 2*ref_extra + 2*npml_ref
            xmin = long_min_interior - real(ref_extra+npml_ref,dp)*dx
        else if (index(cname, 'y_') == 1) then
            ny = n_long_interior + 2*ref_extra + 2*npml_ref
            ymin = long_min_interior - real(ref_extra+npml_ref,dp)*dy
        else
            nz = n_long_interior + 2*ref_extra + 2*npml_ref
            zmin = long_min_interior - real(ref_extra+npml_ref,dp)*dz
        end if
    end subroutine reference_geometry


    subroutine run_one_sim(cname, nx, ny, nz, pml, xmin, ymin, zmin, write_snapshots, probe, e0, e1)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nx, ny, nz, pml
        real(dp), intent(in) :: xmin, ymin, zmin
        logical, intent(in) :: write_snapshots
        real(dp), intent(out) :: probe(0:nstep)
        real(dp), intent(out) :: e0, e1

        real(dp), allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
        real(dp), allocatable :: Hx(:,:,:), Hy(:,:,:), Hz(:,:,:)
        real(dp), allocatable :: aex(:), bex(:), kex(:), aey(:), bey(:), key(:), aez(:), bez(:), kez(:)
        real(dp), allocatable :: ahx(:), bhx(:), khx(:), ahy(:), bhy(:), khy(:), ahz(:), bhz(:), khz(:)
        real(dp), allocatable :: psi_ex_y(:,:,:), psi_ex_z(:,:,:), psi_ey_z(:,:,:), psi_ey_x(:,:,:)
        real(dp), allocatable :: psi_ez_x(:,:,:), psi_ez_y(:,:,:), psi_hx_y(:,:,:), psi_hx_z(:,:,:)
        real(dp), allocatable :: psi_hy_z(:,:,:), psi_hy_x(:,:,:), psi_hz_x(:,:,:), psi_hz_y(:,:,:)
        integer :: n, ip, jp, kp, snap1, snap2
        real(dp) :: x_probe, y_probe, z_probe
        character(len=80) :: slice_name

        allocate(Ex(0:nx-1,0:ny-1,0:nz-1), Ey(0:nx-1,0:ny-1,0:nz-1), Ez(0:nx-1,0:ny-1,0:nz-1))
        allocate(Hx(0:nx-1,0:ny-1,0:nz-1), Hy(0:nx-1,0:ny-1,0:nz-1), Hz(0:nx-1,0:ny-1,0:nz-1))
        allocate(aex(0:nx-1), bex(0:nx-1), kex(0:nx-1), ahx(0:nx-1), bhx(0:nx-1), khx(0:nx-1))
        allocate(aey(0:ny-1), bey(0:ny-1), key(0:ny-1), ahy(0:ny-1), bhy(0:ny-1), khy(0:ny-1))
        allocate(aez(0:nz-1), bez(0:nz-1), kez(0:nz-1), ahz(0:nz-1), bhz(0:nz-1), khz(0:nz-1))
        allocate(psi_ex_y(0:nx-1,0:ny-1,0:nz-1), psi_ex_z(0:nx-1,0:ny-1,0:nz-1))
        allocate(psi_ey_z(0:nx-1,0:ny-1,0:nz-1), psi_ey_x(0:nx-1,0:ny-1,0:nz-1))
        allocate(psi_ez_x(0:nx-1,0:ny-1,0:nz-1), psi_ez_y(0:nx-1,0:ny-1,0:nz-1))
        allocate(psi_hx_y(0:nx-1,0:ny-1,0:nz-1), psi_hx_z(0:nx-1,0:ny-1,0:nz-1))
        allocate(psi_hy_z(0:nx-1,0:ny-1,0:nz-1), psi_hy_x(0:nx-1,0:ny-1,0:nz-1))
        allocate(psi_hz_x(0:nx-1,0:ny-1,0:nz-1), psi_hz_y(0:nx-1,0:ny-1,0:nz-1))

        Ex = 0.0d0; Ey = 0.0d0; Ez = 0.0d0
        Hx = 0.0d0; Hy = 0.0d0; Hz = 0.0d0
        psi_ex_y = 0.0d0; psi_ex_z = 0.0d0; psi_ey_z = 0.0d0; psi_ey_x = 0.0d0
        psi_ez_x = 0.0d0; psi_ez_y = 0.0d0; psi_hx_y = 0.0d0; psi_hx_z = 0.0d0
        psi_hy_z = 0.0d0; psi_hy_x = 0.0d0; psi_hz_x = 0.0d0; psi_hz_y = 0.0d0

        call init_wavepacket(cname, nx, ny, nz, xmin, ymin, zmin, Ex, Ey, Ez, Hx, Hy, Hz)
        call apply_transverse_periodic(cname, nx, ny, nz, Ex, Ey, Ez, Hx, Hy, Hz)
        call init_probe(cname, x_probe, y_probe, z_probe)
        call probe_index(nx, ny, nz, xmin, ymin, zmin, x_probe, y_probe, z_probe, ip, jp, kp)
        call init_cpml_coefficients(nx, ny, nz, pml, aex, bex, kex, aey, bey, key, aez, bez, kez, &
            ahx, bhx, khx, ahy, bhy, khy, ahz, bhz, khz)

        e0 = interior_energy(nx, ny, nz, pml, Ex, Ey, Ez, Hx, Hy, Hz)
        probe(0) = probe_field(cname, Ex, Ey, Ez, ip, jp, kp)
        if (write_snapshots) then
            call make_slice_name(cname, 0, slice_name)
            call write_case_slice(cname, trim(slice_name), nx, ny, nz, Ex, Ey, Ez)
        end if

        snap1 = max(1, nstep/3)
        snap2 = max(snap1+1, (2*nstep)/3)

        do n = 1, nstep
            call step_cpml(cname, nx, ny, nz, pml, Ex, Ey, Ez, Hx, Hy, Hz, aex, bex, kex, aey, bey, key, &
                aez, bez, kez, ahx, bhx, khx, ahy, bhy, khy, ahz, bhz, khz, psi_ex_y, psi_ex_z, &
                psi_ey_z, psi_ey_x, psi_ez_x, psi_ez_y, psi_hx_y, psi_hx_z, psi_hy_z, psi_hy_x, &
                psi_hz_x, psi_hz_y)
            call apply_transverse_periodic(cname, nx, ny, nz, Ex, Ey, Ez, Hx, Hy, Hz)
            probe(n) = probe_field(cname, Ex, Ey, Ez, ip, jp, kp)

            if (write_snapshots) then
                if (n == snap1 .or. n == snap2 .or. n == nstep) then
                    call make_slice_name(cname, n, slice_name)
                    call write_case_slice(cname, trim(slice_name), nx, ny, nz, Ex, Ey, Ez)
                end if
            end if
        end do

        e1 = interior_energy(nx, ny, nz, pml, Ex, Ey, Ez, Hx, Hy, Hz)

        deallocate(Ex,Ey,Ez,Hx,Hy,Hz)
        deallocate(aex,bex,kex,aey,bey,key,aez,bez,kez,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz)
        deallocate(psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        deallocate(psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
    end subroutine run_one_sim


    subroutine apply_transverse_periodic(cname, nx, ny, nz, Ex, Ey, Ez, Hx, Hy, Hz)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nx, ny, nz
        real(dp), intent(inout) :: Ex(0:nx-1,0:ny-1,0:nz-1), Ey(0:nx-1,0:ny-1,0:nz-1), Ez(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: Hx(0:nx-1,0:ny-1,0:nz-1), Hy(0:nx-1,0:ny-1,0:nz-1), Hz(0:nx-1,0:ny-1,0:nz-1)

        if (index(cname, 'x_') == 1) then
            call periodic_y(nx, ny, nz, Ex); call periodic_z(nx, ny, nz, Ex)
            call periodic_y(nx, ny, nz, Ey); call periodic_z(nx, ny, nz, Ey)
            call periodic_y(nx, ny, nz, Ez); call periodic_z(nx, ny, nz, Ez)
            call periodic_y(nx, ny, nz, Hx); call periodic_z(nx, ny, nz, Hx)
            call periodic_y(nx, ny, nz, Hy); call periodic_z(nx, ny, nz, Hy)
            call periodic_y(nx, ny, nz, Hz); call periodic_z(nx, ny, nz, Hz)
        else if (index(cname, 'y_') == 1) then
            call periodic_x(nx, ny, nz, Ex); call periodic_z(nx, ny, nz, Ex)
            call periodic_x(nx, ny, nz, Ey); call periodic_z(nx, ny, nz, Ey)
            call periodic_x(nx, ny, nz, Ez); call periodic_z(nx, ny, nz, Ez)
            call periodic_x(nx, ny, nz, Hx); call periodic_z(nx, ny, nz, Hx)
            call periodic_x(nx, ny, nz, Hy); call periodic_z(nx, ny, nz, Hy)
            call periodic_x(nx, ny, nz, Hz); call periodic_z(nx, ny, nz, Hz)
        else
            call periodic_x(nx, ny, nz, Ex); call periodic_y(nx, ny, nz, Ex)
            call periodic_x(nx, ny, nz, Ey); call periodic_y(nx, ny, nz, Ey)
            call periodic_x(nx, ny, nz, Ez); call periodic_y(nx, ny, nz, Ez)
            call periodic_x(nx, ny, nz, Hx); call periodic_y(nx, ny, nz, Hx)
            call periodic_x(nx, ny, nz, Hy); call periodic_y(nx, ny, nz, Hy)
            call periodic_x(nx, ny, nz, Hz); call periodic_y(nx, ny, nz, Hz)
        end if
    end subroutine apply_transverse_periodic


    subroutine periodic_x(nx, ny, nz, f)
        implicit none

        integer, intent(in) :: nx, ny, nz
        real(dp), intent(inout) :: f(0:nx-1,0:ny-1,0:nz-1)

        f(0,:,:) = f(nx-2,:,:)
        f(nx-1,:,:) = f(1,:,:)
    end subroutine periodic_x


    subroutine periodic_y(nx, ny, nz, f)
        implicit none

        integer, intent(in) :: nx, ny, nz
        real(dp), intent(inout) :: f(0:nx-1,0:ny-1,0:nz-1)

        f(:,0,:) = f(:,ny-2,:)
        f(:,ny-1,:) = f(:,1,:)
    end subroutine periodic_y


    subroutine periodic_z(nx, ny, nz, f)
        implicit none

        integer, intent(in) :: nx, ny, nz
        real(dp), intent(inout) :: f(0:nx-1,0:ny-1,0:nz-1)

        f(:,:,0) = f(:,:,nz-2)
        f(:,:,nz-1) = f(:,:,1)
    end subroutine periodic_z


    subroutine step_cpml(cname, nx, ny, nz, pml, Ex, Ey, Ez, Hx, Hy, Hz, aex, bex, kex, aey, bey, key, &
        aez, bez, kez, ahx, bhx, khx, ahy, bhy, khy, ahz, bhz, khz, psi_ex_y, psi_ex_z, &
        psi_ey_z, psi_ey_x, psi_ez_x, psi_ez_y, psi_hx_y, psi_hx_z, psi_hy_z, psi_hy_x, &
        psi_hz_x, psi_hz_y)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nx, ny, nz, pml
        real(dp), intent(inout) :: Ex(0:nx-1,0:ny-1,0:nz-1), Ey(0:nx-1,0:ny-1,0:nz-1), Ez(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: Hx(0:nx-1,0:ny-1,0:nz-1), Hy(0:nx-1,0:ny-1,0:nz-1), Hz(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(in) :: aex(0:nx-1), bex(0:nx-1), kex(0:nx-1), aey(0:ny-1), bey(0:ny-1), key(0:ny-1)
        real(dp), intent(in) :: aez(0:nz-1), bez(0:nz-1), kez(0:nz-1), ahx(0:nx-1), bhx(0:nx-1), khx(0:nx-1)
        real(dp), intent(in) :: ahy(0:ny-1), bhy(0:ny-1), khy(0:ny-1), ahz(0:nz-1), bhz(0:nz-1), khz(0:nz-1)
        real(dp), intent(inout) :: psi_ex_y(0:nx-1,0:ny-1,0:nz-1), psi_ex_z(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_ey_z(0:nx-1,0:ny-1,0:nz-1), psi_ey_x(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_ez_x(0:nx-1,0:ny-1,0:nz-1), psi_ez_y(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_hx_y(0:nx-1,0:ny-1,0:nz-1), psi_hx_z(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_hy_z(0:nx-1,0:ny-1,0:nz-1), psi_hy_x(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_hz_x(0:nx-1,0:ny-1,0:nz-1), psi_hz_y(0:nx-1,0:ny-1,0:nz-1)

        if (index(cname, 'x_') == 1) then
            call sub_E03_fdtd_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, &
                pml,nx-pml-2,0,ny-2,0,nz-2, Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0)
            call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,pml-1,0,ny-2,0,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
                psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
            call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, nx-pml-1,nx-2,0,ny-2,0,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
                psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
            call sub_E03_fdtd_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, &
                pml,nx-pml-1,1,ny-2,1,nz-2, Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0)
            call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,pml-1,1,ny-2,1,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
                psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
            call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, nx-pml,nx-2,1,ny-2,1,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
                psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        else if (index(cname, 'y_') == 1) then
            call sub_E03_fdtd_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, &
                0,nx-2,pml,ny-pml-2,0,nz-2, Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0)
            call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,nx-2,0,pml-1,0,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
                psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
            call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,nx-2,ny-pml-1,ny-2,0,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
                psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
            call sub_E03_fdtd_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, &
                1,nx-2,pml,ny-pml-1,1,nz-2, Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0)
            call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,nx-2,1,pml-1,1,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
                psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
            call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,nx-2,ny-pml,ny-2,1,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
                psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        else
            call sub_E03_fdtd_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, &
                0,nx-2,0,ny-2,pml,nz-pml-2, Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0)
            call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,nx-2,0,ny-2,0,pml-1, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
                psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
            call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,nx-2,0,ny-2,nz-pml-1,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
                psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
            call sub_E03_fdtd_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, &
                1,nx-2,1,ny-2,pml,nz-pml-1, Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0)
            call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,nx-2,1,ny-2,1,pml-1, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
                psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
            call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,nx-2,1,ny-2,nz-pml,nz-2, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
                psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        end if
    end subroutine step_cpml


    subroutine cpml_h_slabs(nx, ny, nz, pml, Ex, Ey, Ez, Hx, Hy, Hz, ahx, bhx, khx, ahy, bhy, khy, &
        ahz, bhz, khz, psi_hx_y, psi_hx_z, psi_hy_z, psi_hy_x, psi_hz_x, psi_hz_y)
        implicit none

        integer, intent(in) :: nx, ny, nz, pml
        real(dp), intent(inout) :: Ex(0:nx-1,0:ny-1,0:nz-1), Ey(0:nx-1,0:ny-1,0:nz-1), Ez(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: Hx(0:nx-1,0:ny-1,0:nz-1), Hy(0:nx-1,0:ny-1,0:nz-1), Hz(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(in) :: ahx(0:nx-1), bhx(0:nx-1), khx(0:nx-1), ahy(0:ny-1), bhy(0:ny-1), khy(0:ny-1)
        real(dp), intent(in) :: ahz(0:nz-1), bhz(0:nz-1), khz(0:nz-1)
        real(dp), intent(inout) :: psi_hx_y(0:nx-1,0:ny-1,0:nz-1), psi_hx_z(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_hy_z(0:nx-1,0:ny-1,0:nz-1), psi_hy_x(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_hz_x(0:nx-1,0:ny-1,0:nz-1), psi_hz_y(0:nx-1,0:ny-1,0:nz-1)

        call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,nx-2,0,ny-2,0,pml-1, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
            psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
        call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,nx-2,0,ny-2,nz-pml-1,nz-2, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
            psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
        call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,nx-2,0,pml-1,pml,nz-pml-2, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
            psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
        call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,nx-2,ny-pml-1,ny-2,pml,nz-pml-2, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
            psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
        call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, 0,pml-1,pml,ny-pml-2,pml,nz-pml-2, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
            psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
        call sub_E03_cpml_3d_cartesian_H(0,nx-1,0,ny-1,0,nz-1, nx-pml-1,nx-2,pml,ny-pml-2,pml,nz-pml-2, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu0,ahx,bhx,khx,ahy,bhy,khy,ahz,bhz,khz, &
            psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x,psi_hz_y)
    end subroutine cpml_h_slabs


    subroutine cpml_e_slabs(nx, ny, nz, pml, Ex, Ey, Ez, Hx, Hy, Hz, aex, bex, kex, aey, bey, key, &
        aez, bez, kez, psi_ex_y, psi_ex_z, psi_ey_z, psi_ey_x, psi_ez_x, psi_ez_y)
        implicit none

        integer, intent(in) :: nx, ny, nz, pml
        real(dp), intent(inout) :: Ex(0:nx-1,0:ny-1,0:nz-1), Ey(0:nx-1,0:ny-1,0:nz-1), Ez(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: Hx(0:nx-1,0:ny-1,0:nz-1), Hy(0:nx-1,0:ny-1,0:nz-1), Hz(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(in) :: aex(0:nx-1), bex(0:nx-1), kex(0:nx-1), aey(0:ny-1), bey(0:ny-1), key(0:ny-1)
        real(dp), intent(in) :: aez(0:nz-1), bez(0:nz-1), kez(0:nz-1)
        real(dp), intent(inout) :: psi_ex_y(0:nx-1,0:ny-1,0:nz-1), psi_ex_z(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_ey_z(0:nx-1,0:ny-1,0:nz-1), psi_ey_x(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(inout) :: psi_ez_x(0:nx-1,0:ny-1,0:nz-1), psi_ez_y(0:nx-1,0:ny-1,0:nz-1)

        call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,nx-2,1,ny-2,1,pml-1, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
            psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,nx-2,1,ny-2,nz-pml,nz-2, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
            psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,nx-2,1,pml-1,pml,nz-pml-1, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
            psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,nx-2,ny-pml,ny-2,pml,nz-pml-1, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
            psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, 1,pml-1,pml,ny-pml-1,pml,nz-pml-1, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
            psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
        call sub_E03_cpml_3d_cartesian_E(0,nx-1,0,ny-1,0,nz-1, nx-pml,nx-2,pml,ny-pml-1,pml,nz-pml-1, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,eps0,aex,bex,kex,aey,bey,key,aez,bez,kez, &
            psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x,psi_ez_y)
    end subroutine cpml_e_slabs


    subroutine init_wavepacket(cname, nx, ny, nz, xmin, ymin, zmin, Ex, Ey, Ez, Hx, Hy, Hz)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nx, ny, nz
        real(dp), intent(in) :: xmin, ymin, zmin
        real(dp), intent(out) :: Ex(0:nx-1,0:ny-1,0:nz-1), Ey(0:nx-1,0:ny-1,0:nz-1), Ez(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(out) :: Hx(0:nx-1,0:ny-1,0:nz-1), Hy(0:nx-1,0:ny-1,0:nz-1), Hz(0:nx-1,0:ny-1,0:nz-1)

        integer :: i, j, k, sgn
        real(dp) :: x, y, z, xh, yh, zh, center, q, qh, cdt2

        Ex = 0.0d0; Ey = 0.0d0; Ez = 0.0d0
        Hx = 0.0d0; Hy = 0.0d0; Hz = 0.0d0
        cdt2 = 0.5d0*c0*dt

        call packet_center(cname, center, sgn)

        do k = 0, nz-1
        do j = 0, ny-1
        do i = 0, nx-1
            x = xmin + real(i,dp)*dx
            y = ymin + real(j,dp)*dy
            z = zmin + real(k,dp)*dz
            xh = xmin + (real(i,dp)+0.5d0)*dx
            yh = ymin + (real(j,dp)+0.5d0)*dy
            zh = zmin + (real(k,dp)+0.5d0)*dz

            if (index(cname, 'x_') == 1) then
                q = real(sgn,dp)*(x-center)
                qh = real(sgn,dp)*(xh-center) + cdt2
                Ey(i,j,k) = packet_amp*packet_shape(q)
                Hz(i,j,k) = real(sgn,dp)/eta0*packet_amp*packet_shape(qh)
            else if (index(cname, 'y_') == 1) then
                q = real(sgn,dp)*(y-center)
                qh = real(sgn,dp)*(yh-center) + cdt2
                Ez(i,j,k) = packet_amp*packet_shape(q)
                Hx(i,j,k) = real(sgn,dp)/eta0*packet_amp*packet_shape(qh)
            else
                q = real(sgn,dp)*(z-center)
                qh = real(sgn,dp)*(zh-center) + cdt2
                Ex(i,j,k) = packet_amp*packet_shape(q)
                Hy(i,j,k) = real(sgn,dp)/eta0*packet_amp*packet_shape(qh)
            end if
        end do
        end do
        end do
    end subroutine init_wavepacket


    real(dp) function packet_shape(q)
        implicit none

        real(dp), intent(in) :: q

        packet_shape = exp(-(q/sigma_long)**2)*cos(2.0d0*pi*q/lambda0)
    end function packet_shape


    subroutine packet_center(cname, center, sgn)
        implicit none

        character(len=*), intent(in) :: cname
        real(dp), intent(out) :: center
        integer, intent(out) :: sgn

        if (index(cname, 'plus') > 0) then
            center = long_min_interior + packet_margin
            sgn = 1
        else
            center = long_min_interior + real(n_long_interior,dp)*dx - packet_margin
            sgn = -1
        end if
    end subroutine packet_center


    subroutine init_probe(cname, x_probe, y_probe, z_probe)
        implicit none

        character(len=*), intent(in) :: cname
        real(dp), intent(out) :: x_probe, y_probe, z_probe

        x_probe = trans_min_interior + 4.0d0*dx
        y_probe = trans_min_interior + 4.0d0*dy
        z_probe = trans_min_interior + 4.0d0*dz

        if (trim(cname) == 'x_plus') x_probe = long_min_interior + probe_margin
        if (trim(cname) == 'x_minus') x_probe = long_min_interior + real(n_long_interior,dp)*dx - probe_margin
        if (trim(cname) == 'y_plus') y_probe = long_min_interior + probe_margin
        if (trim(cname) == 'y_minus') y_probe = long_min_interior + real(n_long_interior,dp)*dy - probe_margin
        if (trim(cname) == 'z_plus') z_probe = long_min_interior + probe_margin
        if (trim(cname) == 'z_minus') z_probe = long_min_interior + real(n_long_interior,dp)*dz - probe_margin
    end subroutine init_probe


    subroutine make_slice_name(cname, n, fname)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: n
        character(len=*), intent(out) :: fname

        write(fname,'("field_slice_",A,"_",I6.6,".dat")') trim(cname), n
    end subroutine make_slice_name


    subroutine probe_index(nx, ny, nz, xmin, ymin, zmin, x_probe, y_probe, z_probe, ip, jp, kp)
        implicit none

        integer, intent(in) :: nx, ny, nz
        real(dp), intent(in) :: xmin, ymin, zmin, x_probe, y_probe, z_probe
        integer, intent(out) :: ip, jp, kp

        ip = nint((x_probe-xmin)/dx)
        jp = nint((y_probe-ymin)/dy)
        kp = nint((z_probe-zmin)/dz)
        ip = max(1, min(nx-2, ip))
        jp = max(1, min(ny-2, jp))
        kp = max(1, min(nz-2, kp))
    end subroutine probe_index


    real(dp) function probe_field(cname, Ex, Ey, Ez, ip, jp, kp)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: ip, jp, kp
        real(dp), intent(in) :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)

        if (index(cname, 'x_') == 1) then
            probe_field = Ey(ip,jp,kp)
        else if (index(cname, 'y_') == 1) then
            probe_field = Ez(ip,jp,kp)
        else
            probe_field = Ex(ip,jp,kp)
        end if
    end function probe_field


    real(dp) function interior_energy(nx, ny, nz, pml, Ex, Ey, Ez, Hx, Hy, Hz)
        implicit none

        integer, intent(in) :: nx, ny, nz, pml
        real(dp), intent(in) :: Ex(0:nx-1,0:ny-1,0:nz-1), Ey(0:nx-1,0:ny-1,0:nz-1), Ez(0:nx-1,0:ny-1,0:nz-1)
        real(dp), intent(in) :: Hx(0:nx-1,0:ny-1,0:nz-1), Hy(0:nx-1,0:ny-1,0:nz-1), Hz(0:nx-1,0:ny-1,0:nz-1)
        integer :: i, j, k, il, iu, jl, ju, kl, ku

        interior_energy = 0.0d0
        il = 0; iu = nx-1
        jl = 0; ju = ny-1
        kl = 0; ku = nz-1
        if (nx > 2*pml) then
            il = pml; iu = nx-pml-1
        end if
        if (ny > 2*pml) then
            jl = pml; ju = ny-pml-1
        end if
        if (nz > 2*pml) then
            kl = pml; ku = nz-pml-1
        end if

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            interior_energy = interior_energy + 0.5d0*(eps0*(Ex(i,j,k)**2 + Ey(i,j,k)**2 + Ez(i,j,k)**2) + &
                mu0*(Hx(i,j,k)**2 + Hy(i,j,k)**2 + Hz(i,j,k)**2))*dx*dy*dz
        end do
        end do
        end do
    end function interior_energy


    subroutine init_cpml_coefficients(nx, ny, nz, pml, aex, bex, kex, aey, bey, key, aez, bez, kez, &
        ahx, bhx, khx, ahy, bhy, khy, ahz, bhz, khz)
        implicit none

        integer, intent(in) :: nx, ny, nz, pml
        real(dp), intent(out) :: aex(0:nx-1), bex(0:nx-1), kex(0:nx-1), aey(0:ny-1), bey(0:ny-1), key(0:ny-1)
        real(dp), intent(out) :: aez(0:nz-1), bez(0:nz-1), kez(0:nz-1), ahx(0:nx-1), bhx(0:nx-1), khx(0:nx-1)
        real(dp), intent(out) :: ahy(0:ny-1), bhy(0:ny-1), khy(0:ny-1), ahz(0:nz-1), bhz(0:nz-1), khz(0:nz-1)

        call init_axis_coeff(nx, pml, dx, aex, bex, kex, ahx, bhx, khx)
        call init_axis_coeff(ny, pml, dy, aey, bey, key, ahy, bhy, khy)
        call init_axis_coeff(nz, pml, dz, aez, bez, kez, ahz, bhz, khz)
    end subroutine init_cpml_coefficients


    subroutine init_axis_coeff(n, pml, ds, ae, be, ke, ah, bh, kh)
        implicit none

        integer, intent(in) :: n, pml
        real(dp), intent(in) :: ds
        real(dp), intent(out) :: ae(0:n-1), be(0:n-1), ke(0:n-1), ah(0:n-1), bh(0:n-1), kh(0:n-1)
        integer :: i
        real(dp) :: sigma_max, dist_e, dist_h

        sigma_max = -(pml_m+1.0d0)*log(pml_R0)/(2.0d0*eta0*real(pml,dp)*ds)
        do i = 0, n-1
            dist_e = 0.0d0
            if (i < pml) then
                dist_e = real(pml-i,dp)/real(pml,dp)
            else if (i >= n-pml) then
                dist_e = real(i-(n-pml),dp)/real(max(1,pml-1),dp)
            end if
            dist_e = max(0.0d0, min(1.0d0, dist_e))
            call build_cpml_e_coeff(dist_e, sigma_max, ae(i), be(i), ke(i))

            dist_h = 0.0d0
            if (i < pml) then
                dist_h = real(pml-1-i,dp)/real(max(1,pml-1),dp)
            else if (i >= n-pml-1) then
                dist_h = real(i-(n-pml-1),dp)/real(max(1,pml-1),dp)
            end if
            dist_h = max(0.0d0, min(1.0d0, dist_h))
            call build_cpml_h_coeff(dist_h, sigma_max, ah(i), bh(i), kh(i))
        end do
    end subroutine init_axis_coeff


    subroutine build_cpml_e_coeff(dist, sigma_max, ae, be, ke)
        implicit none

        real(dp), intent(in) :: dist, sigma_max
        real(dp), intent(out) :: ae, be, ke
        real(dp) :: sigma_e, alpha_e, kappa

        if (dist > 0.0d0) then
            sigma_e = sigma_max*dist**pml_m
            kappa = 1.0d0 + (kappa_max-1.0d0)*dist**pml_m
            alpha_e = alpha_max*(1.0d0-dist)
        else
            sigma_e = 0.0d0
            kappa = 1.0d0
            alpha_e = 0.0d0
        end if
        call make_cpml_coeff(sigma_e, kappa, alpha_e, dt, eps0, ae, be, ke)
    end subroutine build_cpml_e_coeff


    subroutine build_cpml_h_coeff(dist, sigma_max, ah, bh, kh)
        implicit none

        real(dp), intent(in) :: dist, sigma_max
        real(dp), intent(out) :: ah, bh, kh
        real(dp) :: sigma_e, alpha_e, kappa, sigma_m, alpha_m

        if (dist > 0.0d0) then
            sigma_e = sigma_max*dist**pml_m
            kappa = 1.0d0 + (kappa_max-1.0d0)*dist**pml_m
            alpha_e = alpha_max*(1.0d0-dist)
        else
            sigma_e = 0.0d0
            kappa = 1.0d0
            alpha_e = 0.0d0
        end if
        sigma_m = sigma_e*mu0/eps0
        alpha_m = alpha_e*mu0/eps0
        call make_cpml_coeff(sigma_m, kappa, alpha_m, dt, mu0, ah, bh, kh)
    end subroutine build_cpml_h_coeff


    subroutine make_cpml_coeff(sigma, kappa, alpha, dt_in, medium_param, a, b, kcoef)
        implicit none

        real(dp), intent(in) :: sigma, kappa, alpha, dt_in, medium_param
        real(dp), intent(out) :: a, b, kcoef
        real(dp) :: denom

        kcoef = kappa
        if (sigma <= 0.0d0 .and. alpha <= 0.0d0) then
            a = 0.0d0
            b = 1.0d0
        else
            b = exp(-(sigma/kappa + alpha)*dt_in/medium_param)
            denom = sigma*kappa + kappa*kappa*alpha
            if (denom > 0.0d0) then
                a = sigma*(b-1.0d0)/denom
            else
                a = 0.0d0
            end if
        end if
    end subroutine make_cpml_coeff


    subroutine write_probe(fname, cpml, ref, err_db)
        implicit none

        character(len=*), intent(in) :: fname
        real(dp), intent(in) :: cpml(0:nstep), ref(0:nstep), err_db(0:nstep)
        integer :: n, unit_id

        open(newunit=unit_id, file=fname, status='replace', action='write')
        write(unit_id,'(A)') 'n compact_E reference_E Error_dB'
        do n = 0, nstep
            write(unit_id,'(I8,3(1X,ES24.16))') n, cpml(n), ref(n), err_db(n)
        end do
        close(unit_id)
    end subroutine write_probe


    subroutine write_case_slice(cname, fname, nx, ny, nz, Ex, Ey, Ez)
        implicit none

        character(len=*), intent(in) :: cname, fname
        integer, intent(in) :: nx, ny, nz
        real(dp), intent(in) :: Ex(0:nx-1,0:ny-1,0:nz-1), Ey(0:nx-1,0:ny-1,0:nz-1), Ez(0:nx-1,0:ny-1,0:nz-1)
        integer :: i, j, k, unit_id

        open(newunit=unit_id, file=fname, status='replace', action='write')
        if (index(cname, 'z_') == 1) then
            j = ny/2
            write(unit_id,*) nx, nz
            do i = 0, nx-1
                do k = 0, nz-1
                    write(unit_id,'(ES24.16)', advance='no') Ex(i,j,k)
                end do
                write(unit_id,*)
            end do
        else
            k = nz/2
            write(unit_id,*) nx, ny
            do i = 0, nx-1
                do j = 0, ny-1
                    if (index(cname, 'x_') == 1) then
                        write(unit_id,'(ES24.16)', advance='no') Ey(i,j,k)
                    else
                        write(unit_id,'(ES24.16)', advance='no') Ez(i,j,k)
                    end if
                end do
                write(unit_id,*)
            end do
        end if
        close(unit_id)
    end subroutine write_case_slice


    subroutine write_case_info()
        implicit none

        integer :: unit_id

        open(newunit=unit_id, file='case_info.dat', status='replace', action='write')
        write(unit_id,*) 'mode = 3d_cartesian_ex_ey_ez_hx_hy_hz'
        write(unit_id,*) 'n_long_interior n_trans_interior =', n_long_interior, n_trans_interior
        write(unit_id,*) 'npml npml_ref =', npml, npml_ref
        write(unit_id,*) 'ref_extra =', ref_extra
        write(unit_id,*) 'dx dy dz =', dx, dy, dz
        write(unit_id,*) 'dt =', dt
        write(unit_id,*) 'nstep =', nstep
        write(unit_id,*) 'late_gate =', late_gate
        write(unit_id,*) 'lambda0 =', lambda0
        write(unit_id,*) 'sigma_long =', sigma_long
        write(unit_id,*) 'packet_margin probe_margin =', packet_margin, probe_margin
        write(unit_id,*) 'pml_m pml_R0 kappa_max alpha_max =', pml_m, pml_R0, kappa_max, alpha_max
        close(unit_id)
    end subroutine write_case_info

end program test_3d_cartesian_wavepacket_cpml
