program test_rz_tez_wavepacket_cpml
    use mod_E01_cpml_2d_rz_tez
    use mod_E01_fdtd_2d_rz_tez

    implicit none

    integer, parameter :: dp = kind(1.0)

    real(dp), parameter :: pi   = 3.1415926535897932384626433832795d0
    real(dp), parameter :: c0   = 2.99792458d8
    real(dp), parameter :: mu0  = 4.0d0*pi*1.0d-7
    real(dp), parameter :: eps0 = 1.0d0/(mu0*c0*c0)
    real(dp), parameter :: eta0 = sqrt(mu0/eps0)

    integer, parameter :: npml_ref = 20

    real(dp), parameter :: dr = 1.0d-3
    real(dp), parameter :: dz = 1.0d-3
    real(dp), parameter :: dt = 0.99d0/(c0*sqrt(1.0d0/dr**2 + 1.0d0/dz**2))

    real(dp), parameter :: rmin_interior = 0.312d0
    real(dp), parameter :: rmin_ref_floor = 0.100d0

    real(dp), parameter :: sigma_long = 18.0d-3
    real(dp), parameter :: sigma_trans = 22.0d-3
    real(dp), parameter :: packet_amp = 1.0d0
    real(dp) :: lambda0 = 12.0d-3

    integer :: nr_interior = 136
    integer :: nz_interior = 136
    integer :: nr_ref = 560
    integer :: nz_ref = 560
    integer :: ref_extra = 200
    integer :: nstep = 450
    integer :: late_gate = 260
    integer :: snapshot_stride = 0
    integer :: npml = 12
    integer :: nr_cpml = 160
    integer :: nz_cpml = 160
    real(dp) :: rmin_cpml = 0.300d0
    real(dp) :: zmin_cpml = -0.080d0
    real(dp) :: rmin_ref = 0.100d0
    real(dp) :: zmin_ref = -0.280d0
    real(dp) :: zmin_interior = -0.068d0
    real(dp) :: packet_margin = 36.0d-3
    real(dp) :: probe_margin = 24.0d-3
    real(dp) :: pml_m = 3.5d0
    real(dp) :: pml_R0 = 0.012d0
    real(dp) :: kappa_max = 3.0d0
    real(dp) :: alpha_max = 0.02d0
    character(len=16) :: case_filter = 'all'

    character(len=16), dimension(4), parameter :: cases = (/ &
        'z_plus          ', 'z_minus         ', 'r_plus          ', 'r_minus         ' /)

    call parse_args()
    call configure_cpml_grid()
    call write_case_info()
    call run_all_cases()

contains

    subroutine parse_args()
        implicit none

        character(len=64) :: arg
        integer :: stat, int_value
        real(dp) :: value_mm

        call get_command_argument(1, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) value_mm
            if (value_mm <= 0.0d0) then
                write(*,'(A)') 'ERROR: lambda_mm must be positive.'
                stop 2
            end if
            lambda0 = value_mm*1.0d-3
        end if

        call get_command_argument(2, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) npml
            if (npml < 2 .or. npml > 60) then
                write(*,'(A)') 'ERROR: npml must be in [2, 60].'
                stop 2
            end if
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
            read(arg,*) int_value
            if (int_value < 32) then
                write(*,'(A)') 'ERROR: n_interior must be at least 32.'
                stop 2
            end if
            nr_interior = int_value
            nz_interior = int_value
        end if

        call get_command_argument(9, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) value_mm
            if (value_mm <= 0.0d0) then
                write(*,'(A)') 'ERROR: packet_margin_mm must be positive.'
                stop 2
            end if
            packet_margin = value_mm*1.0d-3
            probe_margin = max(dr, packet_margin-lambda0)
        end if

        call get_command_argument(10, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 1) then
                write(*,'(A)') 'ERROR: nstep must be positive.'
                stop 2
            end if
            nstep = int_value
        end if

        call get_command_argument(11, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) then
                write(*,'(A)') 'ERROR: late_gate must be non-negative.'
                stop 2
            end if
            late_gate = int_value
        end if

        call get_command_argument(12, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) then
                write(*,'(A)') 'ERROR: ref_extra must be non-negative.'
                stop 2
            end if
            ref_extra = int_value
        end if

        call get_command_argument(13, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) then
                write(*,'(A)') 'ERROR: snapshot_stride must be non-negative.'
                stop 2
            end if
            snapshot_stride = int_value
        end if
    end subroutine parse_args


    subroutine configure_cpml_grid()
        implicit none

        real(dp) :: rmax_interior

        zmin_interior = -0.5d0*real(nz_interior,dp)*dz
        nr_cpml = nr_interior + 2*npml
        nz_cpml = nz_interior + 2*npml
        rmin_cpml = rmin_interior - real(npml,dp)*dr
        zmin_cpml = zmin_interior - real(npml,dp)*dz
        rmax_interior = rmin_interior + real(nr_interior-1,dp)*dr
        rmin_ref = max(rmin_ref_floor, rmin_interior-real(ref_extra+npml_ref,dp)*dr)
        zmin_ref = zmin_interior - real(ref_extra+npml_ref,dp)*dz
        nr_ref = nint((rmax_interior+real(ref_extra+npml_ref,dp)*dr-rmin_ref)/dr) + 1
        nz_ref = nz_interior + 2*ref_extra + 2*npml_ref
        if (late_gate > nstep) late_gate = nstep
        if (probe_margin >= packet_margin) then
            write(*,'(A)') 'ERROR: probe_margin must be smaller than packet_margin.'
            stop 2
        end if
        if (2.0d0*packet_margin >= real(min(nr_interior,nz_interior),dp)*dr) then
            write(*,'(A)') 'ERROR: packet_margin is too large for n_interior.'
            stop 2
        end if
    end subroutine configure_cpml_grid

    subroutine run_all_cases()
        implicit none

        integer :: icase, unit_id
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

            call run_one_sim(cname, nr_cpml, nz_cpml, npml, rmin_cpml, zmin_cpml, &
                .true., probe_cpml, e0, e1)
            call run_one_sim(cname, nr_ref, nz_ref, npml_ref, rmin_ref, zmin_ref, &
                .false., probe_ref, e0, e1)

            ref_norm = max(maxval(abs(probe_ref)), 1.0d-300)
            err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
            late_error_db = maxval(err_db(late_gate:nstep))

            call run_one_sim(cname, nr_cpml, nz_cpml, npml, rmin_cpml, zmin_cpml, &
                .false., probe_cpml, e0, e1)
            final_energy_db = 10.0d0*log10(max(e1, 1.0d-300)/max(e0, 1.0d-300))

            write(unit_id,'(A,",",I0,",",ES16.8,",",ES16.8,",",ES16.8)') &
                trim(cname), late_gate, late_error_db, final_energy_db, ref_norm

            call write_probe(trim(cname)//'_probe.dat', probe_cpml, probe_ref, err_db)
        end do

        close(unit_id)
        deallocate(probe_cpml, probe_ref, err_db)
    end subroutine run_all_cases


    subroutine run_one_sim(cname, nr, nz, pml, rmin, zmin, write_snapshots, probe, e0, e1)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nr, nz, pml
        real(dp), intent(in) :: rmin, zmin
        logical, intent(in) :: write_snapshots
        real(dp), intent(out) :: probe(0:nstep)
        real(dp), intent(out) :: e0, e1

        real(dp), allocatable :: Ephi(:,:), Hr(:,:), Hz(:,:)
        real(dp), allocatable :: ae_r(:), be_r(:), ke_r(:)
        real(dp), allocatable :: ae_z(:), be_z(:), ke_z(:)
        real(dp), allocatable :: ah_r(:), bh_r(:), kh_r(:)
        real(dp), allocatable :: ah_z(:), bh_z(:), kh_z(:)
        real(dp), allocatable :: psi_ephi_r(:,:), psi_ephi_z(:,:)
        real(dp), allocatable :: psi_hr_z(:,:), psi_hz_r(:,:)
        integer :: n, ip, kp, snap1, snap2
        real(dp) :: r_probe, z_probe
        character(len=80) :: snap_name

        allocate(Ephi(0:nr-1,0:nz-1), Hr(0:nr-1,0:nz-1), Hz(0:nr-1,0:nz-1))
        allocate(ae_r(0:nr-1), be_r(0:nr-1), ke_r(0:nr-1))
        allocate(ae_z(0:nz-1), be_z(0:nz-1), ke_z(0:nz-1))
        allocate(ah_r(0:nr-1), bh_r(0:nr-1), kh_r(0:nr-1))
        allocate(ah_z(0:nz-1), bh_z(0:nz-1), kh_z(0:nz-1))
        allocate(psi_ephi_r(0:nr-1,0:nz-1), psi_ephi_z(0:nr-1,0:nz-1))
        allocate(psi_hr_z(0:nr-1,0:nz-1), psi_hz_r(0:nr-1,0:nz-1))

        Ephi = 0.0d0
        Hr = 0.0d0
        Hz = 0.0d0
        psi_ephi_r = 0.0d0
        psi_ephi_z = 0.0d0
        psi_hr_z = 0.0d0
        psi_hz_r = 0.0d0

        call init_wavepacket(cname, nr, nz, rmin, zmin, Ephi, Hr, Hz)
        call init_probe(cname, r_probe, z_probe)
        call probe_index(nr, nz, rmin, zmin, r_probe, z_probe, ip, kp)
        call init_cpml_coefficients(nr, nz, pml, dr, dz, dt, eps0, mu0, &
            pml_m, pml_R0, kappa_max, alpha_max, ae_r, be_r, ke_r, ae_z, be_z, ke_z, &
            ah_r, bh_r, kh_r, ah_z, bh_z, kh_z)

        e0 = interior_energy(nr, nz, pml, Ephi, Hr, Hz)
        probe(0) = Ephi(ip,kp)
        if (write_snapshots) then
            call make_snapshot_name(cname, 0, snap_name)
            call write_field('hz_'//trim(snap_name), nr, nz, Hz)
            call write_field('ephi_'//trim(snap_name), nr, nz, Ephi)
        end if

        snap1 = max(1, nstep/3)
        snap2 = max(snap1+1, (2*nstep)/3)

        do n = 1, nstep
            call step_cpml(nr, nz, pml, rmin, Ephi, Hr, Hz, ae_r, be_r, ke_r, ae_z, be_z, &
                ke_z, ah_r, bh_r, kh_r, ah_z, bh_z, kh_z, psi_ephi_r, psi_ephi_z, &
                psi_hr_z, psi_hz_r)

            probe(n) = Ephi(ip,kp)

            if (write_snapshots) then
                if (should_write_snapshot(n, snap1, snap2)) then
                    call make_snapshot_name(cname, n, snap_name)
                    call write_field('hz_'//trim(snap_name), nr, nz, Hz)
                    call write_field('ephi_'//trim(snap_name), nr, nz, Ephi)
                end if
            end if
        end do

        e1 = interior_energy(nr, nz, pml, Ephi, Hr, Hz)
        if (write_snapshots) then
            call write_field('hz_final_'//trim(cname)//'.dat', nr, nz, Hz)
            call write_field('ephi_final_'//trim(cname)//'.dat', nr, nz, Ephi)
        end if

        deallocate(Ephi,Hr,Hz)
        deallocate(ae_r,be_r,ke_r,ae_z,be_z,ke_z)
        deallocate(ah_r,bh_r,kh_r,ah_z,bh_z,kh_z)
        deallocate(psi_ephi_r,psi_ephi_z,psi_hr_z,psi_hz_r)
    end subroutine run_one_sim


    subroutine step_cpml(nr, nz, pml, rmin, Ephi, Hr, Hz, ae_r, be_r, ke_r, ae_z, be_z, &
        ke_z, ah_r, bh_r, kh_r, ah_z, bh_z, kh_z, psi_ephi_r, psi_ephi_z, psi_hr_z, psi_hz_r)
        implicit none

        integer, intent(in) :: nr, nz, pml
        real(dp), intent(in) :: rmin
        real(dp), intent(inout) :: Ephi(0:nr-1,0:nz-1), Hr(0:nr-1,0:nz-1), Hz(0:nr-1,0:nz-1)
        real(dp), intent(in) :: ae_r(0:nr-1), be_r(0:nr-1), ke_r(0:nr-1)
        real(dp), intent(in) :: ae_z(0:nz-1), be_z(0:nz-1), ke_z(0:nz-1)
        real(dp), intent(in) :: ah_r(0:nr-1), bh_r(0:nr-1), kh_r(0:nr-1)
        real(dp), intent(in) :: ah_z(0:nz-1), bh_z(0:nz-1), kh_z(0:nz-1)
        real(dp), intent(inout) :: psi_ephi_r(0:nr-1,0:nz-1), psi_ephi_z(0:nr-1,0:nz-1)
        real(dp), intent(inout) :: psi_hr_z(0:nr-1,0:nz-1), psi_hz_r(0:nr-1,0:nz-1)

        call sub_E01_fdtd_2d_rz_tez_H(0,nr-1,0,nz-1, &
            pml,nr-pml-2,pml,nz-pml-2, Ephi,Hr,Hz,dt,dr,dz,mu0)

        call sub_E01_cpml_2d_rz_tez_H(0,nr-1,0,nz-1, &
            0,nr-2,0,pml-1, Ephi,Hr,Hz,dt,dr,dz,mu0, &
            ah_z,bh_z,kh_z,ah_r,bh_r,kh_r,psi_hr_z,psi_hz_r)
        call sub_E01_cpml_2d_rz_tez_H(0,nr-1,0,nz-1, &
            0,nr-2,nz-pml-1,nz-2, Ephi,Hr,Hz,dt,dr,dz,mu0, &
            ah_z,bh_z,kh_z,ah_r,bh_r,kh_r,psi_hr_z,psi_hz_r)
        call sub_E01_cpml_2d_rz_tez_H(0,nr-1,0,nz-1, &
            0,pml-1,pml,nz-pml-2, Ephi,Hr,Hz,dt,dr,dz,mu0, &
            ah_z,bh_z,kh_z,ah_r,bh_r,kh_r,psi_hr_z,psi_hz_r)
        call sub_E01_cpml_2d_rz_tez_H(0,nr-1,0,nz-1, &
            nr-pml-1,nr-2,pml,nz-pml-2, Ephi,Hr,Hz,dt,dr,dz,mu0, &
            ah_z,bh_z,kh_z,ah_r,bh_r,kh_r,psi_hr_z,psi_hz_r)

        call sub_E01_fdtd_2d_rz_tez_E(0,nr-1,0,nz-1, &
            pml,nr-pml-1,pml,nz-pml-1, Ephi,Hr,Hz,dt,dr,dz,eps0)

        call sub_E01_cpml_2d_rz_tez_E(0,nr-1,0,nz-1, &
            1,nr-2,1,pml-1, Ephi,Hr,Hz,dt,dr,dz,eps0, &
            ae_r,be_r,ke_r,ae_z,be_z,ke_z,psi_ephi_r,psi_ephi_z)
        call sub_E01_cpml_2d_rz_tez_E(0,nr-1,0,nz-1, &
            1,nr-2,nz-pml,nz-2, Ephi,Hr,Hz,dt,dr,dz,eps0, &
            ae_r,be_r,ke_r,ae_z,be_z,ke_z,psi_ephi_r,psi_ephi_z)
        call sub_E01_cpml_2d_rz_tez_E(0,nr-1,0,nz-1, &
            1,pml-1,pml,nz-pml-1, Ephi,Hr,Hz,dt,dr,dz,eps0, &
            ae_r,be_r,ke_r,ae_z,be_z,ke_z,psi_ephi_r,psi_ephi_z)
        call sub_E01_cpml_2d_rz_tez_E(0,nr-1,0,nz-1, &
            nr-pml,nr-2,pml,nz-pml-1, Ephi,Hr,Hz,dt,dr,dz,eps0, &
            ae_r,be_r,ke_r,ae_z,be_z,ke_z,psi_ephi_r,psi_ephi_z)

        Ephi(0,:) = 0.0d0
    end subroutine step_cpml


    subroutine init_wavepacket(cname, nr, nz, rmin, zmin, Ephi, Hr, Hz)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nr, nz
        real(dp), intent(in) :: rmin, zmin
        real(dp), intent(out) :: Ephi(0:nr-1,0:nz-1), Hr(0:nr-1,0:nz-1), Hz(0:nr-1,0:nz-1)

        integer :: i, k, sgn
        real(dp) :: r_e, z_e, r_h, z_h, r_center, z_center, q, qh, trans, cdt2

        Ephi = 0.0d0
        Hr = 0.0d0
        Hz = 0.0d0
        cdt2 = 0.5d0*c0*dt

        call packet_center(cname, r_center, z_center, sgn)

        do k = 0, nz-1
        do i = 0, nr-1
            r_e = rmin + real(i,dp)*dr
            z_e = zmin + real(k,dp)*dz
            r_h = rmin + (real(i,dp)+0.5d0)*dr
            z_h = zmin + (real(k,dp)+0.5d0)*dz

            if (index(cname, 'z_') == 1) then
                q = real(sgn,dp)*(z_e-z_center)
                trans = r_e-r_center
                Ephi(i,k) = packet_amp*packet_shape(q, trans)

                qh = real(sgn,dp)*(z_h-z_center) + cdt2
                Hr(i,k) = -real(sgn,dp)/eta0*packet_amp*packet_shape(qh, r_e-r_center)
            else
                q = real(sgn,dp)*(r_e-r_center)
                trans = z_e-z_center
                Ephi(i,k) = packet_amp*packet_shape(q, trans)

                qh = real(sgn,dp)*(r_h-r_center) + cdt2
                Hz(i,k) = real(sgn,dp)/eta0*packet_amp*packet_shape(qh, z_e-z_center)
            end if
        end do
        end do

        Ephi(0,:) = 0.0d0
    end subroutine init_wavepacket


    real(dp) function packet_shape(q, trans)
        implicit none

        real(dp), intent(in) :: q, trans

        packet_shape = exp(-(q/sigma_long)**2 - (trans/sigma_trans)**2)* &
            cos(2.0d0*pi*q/lambda0)
    end function packet_shape


    subroutine packet_center(cname, r_center, z_center, sgn)
        implicit none

        character(len=*), intent(in) :: cname
        real(dp), intent(out) :: r_center, z_center
        integer, intent(out) :: sgn

        r_center = rmin_interior + 68.0d0*dr
        z_center = zmin_interior + 68.0d0*dz
        sgn = 1

        select case (trim(cname))
        case ('z_plus')
            z_center = zmin_interior + packet_margin
            sgn = 1
        case ('z_minus')
            z_center = zmin_interior + real(nz_interior,dp)*dz - packet_margin
            sgn = -1
        case ('r_plus')
            r_center = rmin_interior + packet_margin
            sgn = 1
        case ('r_minus')
            r_center = rmin_interior + real(nr_interior,dp)*dr - packet_margin
            sgn = -1
        case default
            write(*,'(A,A)') 'Unknown case: ', trim(cname)
            stop 2
        end select
    end subroutine packet_center


    subroutine init_probe(cname, r_probe, z_probe)
        implicit none

        character(len=*), intent(in) :: cname
        real(dp), intent(out) :: r_probe, z_probe

        r_probe = rmin_interior + 68.0d0*dr
        z_probe = zmin_interior + 68.0d0*dz

        select case (trim(cname))
        case ('z_plus')
            z_probe = zmin_interior + probe_margin
        case ('z_minus')
            z_probe = zmin_interior + real(nz_interior,dp)*dz - probe_margin
        case ('r_plus')
            r_probe = rmin_interior + probe_margin
        case ('r_minus')
            r_probe = rmin_interior + real(nr_interior,dp)*dr - probe_margin
        end select
    end subroutine init_probe


    logical function should_write_snapshot(n, snap1, snap2)
        implicit none

        integer, intent(in) :: n, snap1, snap2

        if (snapshot_stride > 0) then
            should_write_snapshot = (mod(n, snapshot_stride) == 0 .or. n == nstep)
        else
            should_write_snapshot = (n == snap1 .or. n == snap2 .or. n == nstep)
        end if
    end function should_write_snapshot


    subroutine make_snapshot_name(cname, n, fname)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: n
        character(len=*), intent(out) :: fname

        write(fname,'("snapshot_",A,"_",I6.6,".dat")') trim(cname), n
    end subroutine make_snapshot_name


    subroutine probe_index(nr, nz, rmin, zmin, r_probe, z_probe, ip, kp)
        implicit none

        integer, intent(in) :: nr, nz
        real(dp), intent(in) :: rmin, zmin, r_probe, z_probe
        integer, intent(out) :: ip, kp

        ip = nint((r_probe-rmin)/dr)
        kp = nint((z_probe-zmin)/dz)
        ip = max(1, min(nr-2, ip))
        kp = max(1, min(nz-2, kp))
    end subroutine probe_index


    real(dp) function interior_energy(nr, nz, pml, Ephi, Hr, Hz)
        implicit none

        integer, intent(in) :: nr, nz, pml
        real(dp), intent(in) :: Ephi(0:nr-1,0:nz-1), Hr(0:nr-1,0:nz-1), Hz(0:nr-1,0:nz-1)
        integer :: i, k

        interior_energy = 0.0d0
        do k = pml, nz-pml-1
        do i = pml, nr-pml-1
            interior_energy = interior_energy + 0.5d0*(eps0*Ephi(i,k)**2 + &
                mu0*(Hr(i,k)**2 + Hz(i,k)**2))*dr*dz
        end do
        end do
    end function interior_energy


    subroutine init_cpml_coefficients(nr, nz, pml, dr_in, dz_in, dt_in, eps0_in, mu0_in, &
        pml_m_in, pml_R0_in, kappa_max_in, alpha_max_in, ae_r, be_r, ke_r, ae_z, be_z, ke_z, &
        ah_r, bh_r, kh_r, ah_z, bh_z, kh_z)
        implicit none

        integer, intent(in) :: nr, nz, pml
        real(dp), intent(in) :: dr_in, dz_in, dt_in, eps0_in, mu0_in
        real(dp), intent(in) :: pml_m_in, pml_R0_in, kappa_max_in, alpha_max_in
        real(dp), intent(out) :: ae_r(0:nr-1), be_r(0:nr-1), ke_r(0:nr-1)
        real(dp), intent(out) :: ae_z(0:nz-1), be_z(0:nz-1), ke_z(0:nz-1)
        real(dp), intent(out) :: ah_r(0:nr-1), bh_r(0:nr-1), kh_r(0:nr-1)
        real(dp), intent(out) :: ah_z(0:nz-1), bh_z(0:nz-1), kh_z(0:nz-1)

        integer :: i, k
        real(dp) :: sigma_r_max, sigma_z_max, dist_e, dist_h

        sigma_r_max = -(pml_m_in+1.0d0)*log(pml_R0_in)/(2.0d0*eta0*real(pml,dp)*dr_in)
        sigma_z_max = -(pml_m_in+1.0d0)*log(pml_R0_in)/(2.0d0*eta0*real(pml,dp)*dz_in)

        do i = 0, nr-1
            dist_e = 0.0d0
            if (i < pml) then
                dist_e = real(pml-i,dp)/real(pml,dp)
            else if (i >= nr-pml) then
                dist_e = real(i-(nr-pml),dp)/real(max(1,pml-1),dp)
            end if
            dist_e = max(0.0d0, min(1.0d0, dist_e))
            call build_cpml_e_coeff(dist_e, sigma_r_max, pml_m_in, kappa_max_in, alpha_max_in, &
                dt_in, eps0_in, ae_r(i), be_r(i), ke_r(i))

            dist_h = 0.0d0
            if (i < pml) then
                dist_h = real(pml-1-i,dp)/real(max(1,pml-1),dp)
            else if (i >= nr-pml-1) then
                dist_h = real(i-(nr-pml-1),dp)/real(max(1,pml-1),dp)
            end if
            dist_h = max(0.0d0, min(1.0d0, dist_h))
            call build_cpml_h_coeff(dist_h, sigma_r_max, pml_m_in, kappa_max_in, alpha_max_in, &
                dt_in, eps0_in, mu0_in, ah_r(i), bh_r(i), kh_r(i))
        end do

        do k = 0, nz-1
            dist_e = 0.0d0
            if (k < pml) then
                dist_e = real(pml-1-k,dp)/real(max(1,pml-1),dp)
            else if (k >= nz-pml) then
                dist_e = real(k-(nz-pml),dp)/real(max(1,pml-1),dp)
            end if
            dist_e = max(0.0d0, min(1.0d0, dist_e))
            call build_cpml_e_coeff(dist_e, sigma_z_max, pml_m_in, kappa_max_in, alpha_max_in, &
                dt_in, eps0_in, ae_z(k), be_z(k), ke_z(k))

            dist_h = 0.0d0
            if (k < pml) then
                dist_h = real(pml-1-k,dp)/real(max(1,pml-1),dp)
            else if (k >= nz-pml-1) then
                dist_h = real(k-(nz-pml-1),dp)/real(max(1,pml-1),dp)
            end if
            dist_h = max(0.0d0, min(1.0d0, dist_h))
            call build_cpml_h_coeff(dist_h, sigma_z_max, pml_m_in, kappa_max_in, alpha_max_in, &
                dt_in, eps0_in, mu0_in, ah_z(k), bh_z(k), kh_z(k))
        end do
    end subroutine init_cpml_coefficients


    subroutine build_cpml_e_coeff(dist, sigma_max, pml_m_in, kappa_max_in, alpha_max_in, dt_in, eps0_in, ae, be, ke)
        implicit none

        real(dp), intent(in) :: dist, sigma_max, pml_m_in, kappa_max_in, alpha_max_in, dt_in, eps0_in
        real(dp), intent(out) :: ae, be, ke
        real(dp) :: sigma_e, alpha_e, kappa

        if (dist > 0.0d0) then
            sigma_e = sigma_max*dist**pml_m_in
            kappa = 1.0d0 + (kappa_max_in-1.0d0)*dist**pml_m_in
            alpha_e = alpha_max_in*(1.0d0-dist)
        else
            sigma_e = 0.0d0
            kappa = 1.0d0
            alpha_e = 0.0d0
        end if
        call make_cpml_coeff(sigma_e, kappa, alpha_e, dt_in, eps0_in, ae, be, ke)
    end subroutine build_cpml_e_coeff


    subroutine build_cpml_h_coeff(dist, sigma_max, pml_m_in, kappa_max_in, alpha_max_in, dt_in, eps0_in, mu0_in, ah, bh, kh)
        implicit none

        real(dp), intent(in) :: dist, sigma_max, pml_m_in, kappa_max_in, alpha_max_in, dt_in, eps0_in, mu0_in
        real(dp), intent(out) :: ah, bh, kh
        real(dp) :: sigma_e, alpha_e, kappa, sigma_m, alpha_m

        if (dist > 0.0d0) then
            sigma_e = sigma_max*dist**pml_m_in
            kappa = 1.0d0 + (kappa_max_in-1.0d0)*dist**pml_m_in
            alpha_e = alpha_max_in*(1.0d0-dist)
        else
            sigma_e = 0.0d0
            kappa = 1.0d0
            alpha_e = 0.0d0
        end if
        sigma_m = sigma_e*mu0_in/eps0_in
        alpha_m = alpha_e*mu0_in/eps0_in
        call make_cpml_coeff(sigma_m, kappa, alpha_m, dt_in, mu0_in, ah, bh, kh)
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
        write(unit_id,'(A)') 'n compact_Ephi reference_Ephi Error_dB'
        do n = 0, nstep
            write(unit_id,'(I8,3(1X,ES24.16))') n, cpml(n), ref(n), err_db(n)
        end do
        close(unit_id)
    end subroutine write_probe


    subroutine write_field(fname, nr, nz, field)
        implicit none

        character(len=*), intent(in) :: fname
        integer, intent(in) :: nr, nz
        real(dp), intent(in) :: field(0:nr-1,0:nz-1)
        integer :: i, k, unit_id

        open(newunit=unit_id, file=fname, status='replace', action='write')
        write(unit_id,*) nr, nz
        do i = 0, nr-1
            do k = 0, nz-1
                write(unit_id,'(ES24.16)', advance='no') field(i,k)
            end do
            write(unit_id,*)
        end do
        close(unit_id)
    end subroutine write_field


    subroutine write_case_info()
        implicit none

        integer :: unit_id

        open(newunit=unit_id, file='case_info.dat', status='replace', action='write')
        write(unit_id,*) 'mode = rz_tez_ephi_hr_hz'
        write(unit_id,*) 'nr_interior nz_interior =', nr_interior, nz_interior
        write(unit_id,*) 'nr_cpml nz_cpml =', nr_cpml, nz_cpml
        write(unit_id,*) 'nr_ref nz_ref =', nr_ref, nz_ref
        write(unit_id,*) 'ref_extra =', ref_extra
        write(unit_id,*) 'npml npml_ref =', npml, npml_ref
        write(unit_id,*) 'dr dz =', dr, dz
        write(unit_id,*) 'dt =', dt
        write(unit_id,*) 'nstep =', nstep
        write(unit_id,*) 'late_gate =', late_gate
        write(unit_id,*) 'snapshot_stride =', snapshot_stride
        write(unit_id,*) 'rmin_interior zmin_interior =', rmin_interior, zmin_interior
        write(unit_id,*) 'rmin_cpml zmin_cpml =', rmin_cpml, zmin_cpml
        write(unit_id,*) 'rmin_ref zmin_ref =', rmin_ref, zmin_ref
        write(unit_id,*) 'lambda0 =', lambda0
        write(unit_id,*) 'sigma_long sigma_trans =', sigma_long, sigma_trans
        write(unit_id,*) 'packet_margin probe_margin =', packet_margin, probe_margin
        write(unit_id,*) 'pml_m pml_R0 kappa_max alpha_max =', pml_m, pml_R0, kappa_max, alpha_max
        close(unit_id)
    end subroutine write_case_info

end program test_rz_tez_wavepacket_cpml
