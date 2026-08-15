program test_3d_cylindrical_wavepacket_cpml
    use mod_E02_cpml_3d_cylindrical
    use mod_E02_fdtd_3d_cylindrical

    implicit none

    integer, parameter :: dp = kind(1.0)

    real(dp), parameter :: pi = 3.1415926535897932384626433832795d0
    real(dp), parameter :: c0 = 2.99792458d8
    real(dp), parameter :: mu0 = 4.0d0*pi*1.0d-7
    real(dp), parameter :: eps0 = 1.0d0/(mu0*c0*c0)
    real(dp), parameter :: eta0 = sqrt(mu0/eps0)

    integer, parameter :: nr = 48
    integer, parameter :: nphi = 4
    integer, parameter :: npml_ref = 20

    real(dp), parameter :: dr = 1.0d-3
    real(dp), parameter :: dz = 1.0d-3
    real(dp), parameter :: dphi = 2.0d0*pi/real(nphi,dp)
    real(dp), parameter :: dt = 0.80d0/(c0*sqrt(1.0d0/dr**2 + 1.0d0/dz**2 + &
        1.0d0/(0.5d0*dr*dphi)**2))

    real(dp), parameter :: packet_amp = 1.0d0
    real(dp), parameter :: tm01_root = 2.4048255576957728d0
    real(dp), parameter :: prep_source_distance = 96.0d-3

    integer :: n_long_interior = 136
    integer :: nz_cpml = 160
    integer :: nz_ref = 576
    integer :: ref_extra = 200
    integer :: nstep = 450
    integer :: late_gate = 260
    integer :: snapshot_stride = 0
    integer :: npml = 12
    real(dp) :: lambda0 = 18.0d-3
    real(dp) :: sigma_long = 18.0d-3
    real(dp) :: long_min_interior = -0.068d0
    real(dp) :: zmin_cpml = -0.080d0
    real(dp) :: zmin_ref = -0.280d0
    real(dp) :: packet_margin = 36.0d-3
    real(dp) :: probe_margin = 18.0d-3
    real(dp) :: pml_m = 3.5d0
    real(dp) :: pml_R0 = 0.012d0
    real(dp) :: kappa_max = 3.0d0
    real(dp) :: alpha_max = 0.02d0
    character(len=16) :: case_filter = 'all'

    character(len=16), dimension(2), parameter :: cases = (/ &
        'z_plus          ', 'z_minus         ' /)

    call parse_args()
    call update_derived_setup()
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
            probe_margin = max(dz, packet_margin-lambda0)
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

        call get_command_argument(14, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) stop 'ERROR: snapshot_stride must be non-negative.'
            snapshot_stride = int_value
        end if
    end subroutine parse_args


    subroutine update_derived_setup()
        implicit none

        long_min_interior = -0.5d0*real(n_long_interior,dp)*dz
        nz_cpml = n_long_interior + 2*npml
        nz_ref = n_long_interior + 2*ref_extra + 2*npml_ref
        zmin_cpml = long_min_interior - real(npml,dp)*dz
        zmin_ref = long_min_interior - real(ref_extra+npml_ref,dp)*dz
        if (late_gate > nstep) late_gate = nstep
        if (probe_margin >= packet_margin) stop 'ERROR: probe_margin must be smaller than packet_margin.'
        if (2.0d0*packet_margin >= real(n_long_interior,dp)*dz) &
            stop 'ERROR: packet_margin is too large for n_long_interior.'
    end subroutine update_derived_setup


    subroutine run_all_cases()
        implicit none

        integer :: icase, unit_id
        real(dp), allocatable :: probe_cpml(:), probe_ref(:), err_db(:)
        real(dp) :: e0_cpml, e1_cpml, e0_ref, e1_ref, late_error_db, final_energy_db, ref_norm
        character(len=16) :: cname

        allocate(probe_cpml(0:nstep), probe_ref(0:nstep), err_db(0:nstep))

        open(newunit=unit_id, file='metrics.dat', status='replace', action='write')
        write(unit_id,'(A)') 'case,late_gate_step,late_reflection_error_db,final_interior_energy_db,max_abs_ref_probe'

        do icase = 1, size(cases)
            cname = trim(cases(icase))
            if (trim(case_filter) /= 'all' .and. trim(case_filter) /= trim(cname)) cycle
            write(*,'(A,A)') 'Running case: ', trim(cname)

            call run_one_sim(cname, nz_cpml, npml, zmin_cpml, .true., probe_cpml, e0_cpml, e1_cpml)
            call run_one_sim(cname, nz_ref, npml_ref, zmin_ref, .false., probe_ref, e0_ref, e1_ref)

            ref_norm = max(maxval(abs(probe_ref)), 1.0d-300)
            err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
            late_error_db = maxval(err_db(late_gate:nstep))
            final_energy_db = 10.0d0*log10(max(e1_cpml, 1.0d-300)/max(e0_cpml, 1.0d-300))

            write(unit_id,'(A,",",I0,",",ES16.8,",",ES16.8,",",ES16.8)') &
                trim(cname), late_gate, late_error_db, final_energy_db, ref_norm
            call write_probe(trim(cname)//'_probe.dat', probe_cpml, probe_ref, err_db)
        end do

        close(unit_id)
        deallocate(probe_cpml, probe_ref, err_db)
    end subroutine run_all_cases


    subroutine run_one_sim(cname, nz, pml, zmin, write_snapshots, probe, e0, e1)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nz, pml
        real(dp), intent(in) :: zmin
        logical, intent(in) :: write_snapshots
        real(dp), intent(out) :: probe(0:nstep)
        real(dp), intent(out) :: e0, e1

        real(dp), allocatable :: Er(:,:,:), Ephi(:,:,:), Ez(:,:,:)
        real(dp), allocatable :: Hr(:,:,:), Hphi(:,:,:), Hz(:,:,:)
        real(dp), allocatable :: ar(:), br(:), kr(:), ap(:), bp(:), kp(:)
        real(dp), allocatable :: ae_z(:), be_z(:), ke_z(:), ah_z(:), bh_z(:), kh_z(:)
        real(dp), allocatable :: psi_E_r_phi(:,:,:), psi_E_r_z(:,:,:), psi_E_phi_z(:,:,:)
        real(dp), allocatable :: psi_E_phi_r(:,:,:), psi_E_z_r(:,:,:), psi_E_z_phi(:,:,:)
        real(dp), allocatable :: psi_H_r_z(:,:,:), psi_H_r_phi(:,:,:), psi_H_phi_r(:,:,:)
        real(dp), allocatable :: psi_H_phi_z(:,:,:), psi_H_z_phi(:,:,:), psi_H_z_r(:,:,:)
        integer :: n, ip, jp, kpidx, snap1, snap2, snap3
        real(dp) :: r_probe, z_probe
        character(len=80) :: slice_name

        allocate(Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz))
        allocate(Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz))
        allocate(ar(0:nr), br(0:nr), kr(0:nr), ap(0:nphi+1), bp(0:nphi+1), kp(0:nphi+1))
        allocate(ae_z(0:nz), be_z(0:nz), ke_z(0:nz), ah_z(0:nz), bh_z(0:nz), kh_z(0:nz))
        allocate(psi_E_r_phi(0:nr,0:nphi+1,0:nz), psi_E_r_z(0:nr,0:nphi+1,0:nz))
        allocate(psi_E_phi_z(0:nr,0:nphi+1,0:nz), psi_E_phi_r(0:nr,0:nphi+1,0:nz))
        allocate(psi_E_z_r(0:nr,0:nphi+1,0:nz), psi_E_z_phi(0:nr,0:nphi+1,0:nz))
        allocate(psi_H_r_z(0:nr,0:nphi+1,0:nz), psi_H_r_phi(0:nr,0:nphi+1,0:nz))
        allocate(psi_H_phi_r(0:nr,0:nphi+1,0:nz), psi_H_phi_z(0:nr,0:nphi+1,0:nz))
        allocate(psi_H_z_phi(0:nr,0:nphi+1,0:nz), psi_H_z_r(0:nr,0:nphi+1,0:nz))

        Er = 0.0d0; Ephi = 0.0d0; Ez = 0.0d0
        Hr = 0.0d0; Hphi = 0.0d0; Hz = 0.0d0
        psi_E_r_phi = 0.0d0; psi_E_r_z = 0.0d0; psi_E_phi_z = 0.0d0
        psi_E_phi_r = 0.0d0; psi_E_z_r = 0.0d0; psi_E_z_phi = 0.0d0
        psi_H_r_z = 0.0d0; psi_H_r_phi = 0.0d0; psi_H_phi_r = 0.0d0
        psi_H_phi_z = 0.0d0; psi_H_z_phi = 0.0d0; psi_H_z_r = 0.0d0

        call init_wavepacket(cname, nz, zmin, Er, Ephi, Ez, Hr, Hphi, Hz)
        call fill_boundaries(nz, Er, Ephi, Ez, Hr, Hphi, Hz)
        call init_probe(cname, r_probe, z_probe)
        call probe_index(nz, zmin, r_probe, z_probe, ip, jp, kpidx)
        call init_cpml_coefficients(nz, pml, ar, br, kr, ap, bp, kp, ae_z, be_z, ke_z, ah_z, bh_z, kh_z)

        e0 = interior_energy(nz, pml, Er, Ephi, Ez, Hr, Hphi, Hz)
        probe(0) = Ez(ip,jp,kpidx)
        if (write_snapshots) then
            call make_slice_name(cname, 0, slice_name)
            call write_ez_slice(trim(slice_name), nz, Ez)
        end if

        snap1 = max(1, nstep/6)
        snap2 = max(snap1+1, nstep/3)
        snap3 = max(snap2+1, (2*nstep)/3)

        do n = 1, nstep
            call step_cpml(nz, pml, Er, Ephi, Ez, Hr, Hphi, Hz, ar, br, kr, ap, bp, kp, &
                ae_z, be_z, ke_z, ah_z, bh_z, kh_z, psi_E_r_phi, psi_E_r_z, psi_E_phi_z, &
                psi_E_phi_r, psi_E_z_r, psi_E_z_phi, psi_H_r_z, psi_H_r_phi, psi_H_phi_r, &
                psi_H_phi_z, psi_H_z_phi, psi_H_z_r)
            call fill_boundaries(nz, Er, Ephi, Ez, Hr, Hphi, Hz)

            probe(n) = Ez(ip,jp,kpidx)

            if (write_snapshots) then
                if (should_write_snapshot(n, snap1, snap2, snap3)) then
                    call make_slice_name(cname, n, slice_name)
                    call write_ez_slice(trim(slice_name), nz, Ez)
                end if
            end if
        end do

        e1 = interior_energy(nz, pml, Er, Ephi, Ez, Hr, Hphi, Hz)

        deallocate(Er, Ephi, Ez, Hr, Hphi, Hz)
        deallocate(ar, br, kr, ap, bp, kp, ae_z, be_z, ke_z, ah_z, bh_z, kh_z)
        deallocate(psi_E_r_phi, psi_E_r_z, psi_E_phi_z, psi_E_phi_r, psi_E_z_r, psi_E_z_phi)
        deallocate(psi_H_r_z, psi_H_r_phi, psi_H_phi_r, psi_H_phi_z, psi_H_z_phi, psi_H_z_r)
    end subroutine run_one_sim


    subroutine step_cpml(nz, pml, Er, Ephi, Ez, Hr, Hphi, Hz, ar, br, kr, ap, bp, kp, &
        ae_z, be_z, ke_z, ah_z, bh_z, kh_z, psi_E_r_phi, psi_E_r_z, psi_E_phi_z, &
        psi_E_phi_r, psi_E_z_r, psi_E_z_phi, psi_H_r_z, psi_H_r_phi, psi_H_phi_r, &
        psi_H_phi_z, psi_H_z_phi, psi_H_z_r)
        implicit none

        integer, intent(in) :: nz, pml
        real(dp), intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real(dp), intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        real(dp), intent(in) :: ar(0:nr), br(0:nr), kr(0:nr), ap(0:nphi+1), bp(0:nphi+1), kp(0:nphi+1)
        real(dp), intent(in) :: ae_z(0:nz), be_z(0:nz), ke_z(0:nz), ah_z(0:nz), bh_z(0:nz), kh_z(0:nz)
        real(dp), intent(inout) :: psi_E_r_phi(0:nr,0:nphi+1,0:nz), psi_E_r_z(0:nr,0:nphi+1,0:nz)
        real(dp), intent(inout) :: psi_E_phi_z(0:nr,0:nphi+1,0:nz), psi_E_phi_r(0:nr,0:nphi+1,0:nz)
        real(dp), intent(inout) :: psi_E_z_r(0:nr,0:nphi+1,0:nz), psi_E_z_phi(0:nr,0:nphi+1,0:nz)
        real(dp), intent(inout) :: psi_H_r_z(0:nr,0:nphi+1,0:nz), psi_H_r_phi(0:nr,0:nphi+1,0:nz)
        real(dp), intent(inout) :: psi_H_phi_r(0:nr,0:nphi+1,0:nz), psi_H_phi_z(0:nr,0:nphi+1,0:nz)
        real(dp), intent(inout) :: psi_H_z_phi(0:nr,0:nphi+1,0:nz), psi_H_z_r(0:nr,0:nphi+1,0:nz)

        call sub_E02_fdtd_3d_cylindrical_H(0,nr,0,nphi+1,0,nz, &
            1,nr-1,1,nphi,pml,nz-pml-1, Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu0)

        call sub_E02_cpml_3d_cylindrical_H(0,nr,0,nphi+1,0,nz, &
            1,nr-1,1,nphi,0,pml-1, Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu0, &
            ah_z,bh_z,kh_z,ap,bp,kp,ar,br,kr,ah_z,bh_z,kh_z,ap,bp,kp,ar,br,kr, &
            psi_H_r_z,psi_H_r_phi,psi_H_phi_r,psi_H_phi_z,psi_H_z_phi,psi_H_z_r)
        call sub_E02_cpml_3d_cylindrical_H(0,nr,0,nphi+1,0,nz, &
            1,nr-1,1,nphi,nz-pml,nz-1, Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu0, &
            ah_z,bh_z,kh_z,ap,bp,kp,ar,br,kr,ah_z,bh_z,kh_z,ap,bp,kp,ar,br,kr, &
            psi_H_r_z,psi_H_r_phi,psi_H_phi_r,psi_H_phi_z,psi_H_z_phi,psi_H_z_r)

        call project_tm_h(nz, Hr, Hz)
        call fill_h_boundaries(nz, Hr, Hphi, Hz)

        call sub_E02_fdtd_3d_cylindrical_E(0,nr,0,nphi+1,0,nz, &
            1,nr-1,1,nphi,pml+1,nz-pml-1, Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,eps0)

        call sub_E02_cpml_3d_cylindrical_E(0,nr,0,nphi+1,0,nz, &
            1,nr-1,1,nphi,1,pml, Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,eps0, &
            ap,bp,kp,ae_z,be_z,ke_z,ae_z,be_z,ke_z,ar,br,kr,ar,br,kr,ap,bp,kp, &
            psi_E_r_phi,psi_E_r_z,psi_E_phi_z,psi_E_phi_r,psi_E_z_r,psi_E_z_phi)
        call sub_E02_cpml_3d_cylindrical_E(0,nr,0,nphi+1,0,nz, &
            1,nr-1,1,nphi,nz-pml,nz-1, Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,eps0, &
            ap,bp,kp,ae_z,be_z,ke_z,ae_z,be_z,ke_z,ar,br,kr,ar,br,kr,ap,bp,kp, &
            psi_E_r_phi,psi_E_r_z,psi_E_phi_z,psi_E_phi_r,psi_E_z_r,psi_E_z_phi)

        call project_tm_e(nz, Ephi)
    end subroutine step_cpml


    subroutine init_wavepacket(cname, nz, zmin, Er, Ephi, Ez, Hr, Hphi, Hz)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nz
        real(dp), intent(in) :: zmin
        real(dp), intent(out) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real(dp), intent(out) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)

        real(dp), allocatable :: Er_src(:,:,:), Ephi_src(:,:,:), Ez_src(:,:,:)
        real(dp), allocatable :: Hr_src(:,:,:), Hphi_src(:,:,:), Hz_src(:,:,:)
        integer :: i, j, k, ks
        real(dp) :: z, compact_zmax

        Er = 0.0d0; Ephi = 0.0d0; Ez = 0.0d0
        Hr = 0.0d0; Hphi = 0.0d0; Hz = 0.0d0

        allocate(Er_src(0:nr,0:nphi+1,0:nz_ref), Ephi_src(0:nr,0:nphi+1,0:nz_ref), &
            Ez_src(0:nr,0:nphi+1,0:nz_ref))
        allocate(Hr_src(0:nr,0:nphi+1,0:nz_ref), Hphi_src(0:nr,0:nphi+1,0:nz_ref), &
            Hz_src(0:nr,0:nphi+1,0:nz_ref))

        call prepare_source_packet(cname, Er_src, Ephi_src, Ez_src, Hr_src, Hphi_src, Hz_src)

        compact_zmax = zmin_cpml + real(nz_cpml,dp)*dz
        do k = 0, nz
            z = zmin + real(k,dp)*dz
            if (z < zmin_cpml-0.5d0*dz .or. z > compact_zmax+0.5d0*dz) cycle
            ks = nint((z-zmin_ref)/dz)
            if (ks < 0 .or. ks > nz_ref) cycle
            do j = 0, nphi+1
            do i = 0, nr
                Er(i,j,k) = Er_src(i,j,ks)
                Ephi(i,j,k) = Ephi_src(i,j,ks)
                Ez(i,j,k) = Ez_src(i,j,ks)
                Hr(i,j,k) = Hr_src(i,j,ks)
                Hphi(i,j,k) = Hphi_src(i,j,ks)
                Hz(i,j,k) = Hz_src(i,j,ks)
            end do
            end do
        end do

        call fill_boundaries(nz, Er, Ephi, Ez, Hr, Hphi, Hz)

        deallocate(Er_src, Ephi_src, Ez_src, Hr_src, Hphi_src, Hz_src)
    end subroutine init_wavepacket


    subroutine prepare_source_packet(cname, Er, Ephi, Ez, Hr, Hphi, Hz)
        implicit none

        character(len=*), intent(in) :: cname
        real(dp), intent(out) :: Er(0:nr,0:nphi+1,0:nz_ref), Ephi(0:nr,0:nphi+1,0:nz_ref), Ez(0:nr,0:nphi+1,0:nz_ref)
        real(dp), intent(out) :: Hr(0:nr,0:nphi+1,0:nz_ref), Hphi(0:nr,0:nphi+1,0:nz_ref), Hz(0:nr,0:nphi+1,0:nz_ref)

        real(dp), allocatable :: ar(:), br(:), kr(:), ap(:), bp(:), kp(:)
        real(dp), allocatable :: ae_z(:), be_z(:), ke_z(:), ah_z(:), bh_z(:), kh_z(:)
        real(dp), allocatable :: psi_E_r_phi(:,:,:), psi_E_r_z(:,:,:), psi_E_phi_z(:,:,:)
        real(dp), allocatable :: psi_E_phi_r(:,:,:), psi_E_z_r(:,:,:), psi_E_z_phi(:,:,:)
        real(dp), allocatable :: psi_H_r_z(:,:,:), psi_H_r_phi(:,:,:), psi_H_phi_r(:,:,:)
        real(dp), allocatable :: psi_H_phi_z(:,:,:), psi_H_z_phi(:,:,:), psi_H_z_r(:,:,:)
        integer :: n, nprep

        allocate(ar(0:nr), br(0:nr), kr(0:nr), ap(0:nphi+1), bp(0:nphi+1), kp(0:nphi+1))
        allocate(ae_z(0:nz_ref), be_z(0:nz_ref), ke_z(0:nz_ref), ah_z(0:nz_ref), bh_z(0:nz_ref), kh_z(0:nz_ref))
        allocate(psi_E_r_phi(0:nr,0:nphi+1,0:nz_ref), psi_E_r_z(0:nr,0:nphi+1,0:nz_ref))
        allocate(psi_E_phi_z(0:nr,0:nphi+1,0:nz_ref), psi_E_phi_r(0:nr,0:nphi+1,0:nz_ref))
        allocate(psi_E_z_r(0:nr,0:nphi+1,0:nz_ref), psi_E_z_phi(0:nr,0:nphi+1,0:nz_ref))
        allocate(psi_H_r_z(0:nr,0:nphi+1,0:nz_ref), psi_H_r_phi(0:nr,0:nphi+1,0:nz_ref))
        allocate(psi_H_phi_r(0:nr,0:nphi+1,0:nz_ref), psi_H_phi_z(0:nr,0:nphi+1,0:nz_ref))
        allocate(psi_H_z_phi(0:nr,0:nphi+1,0:nz_ref), psi_H_z_r(0:nr,0:nphi+1,0:nz_ref))

        Er = 0.0d0; Ephi = 0.0d0; Ez = 0.0d0
        Hr = 0.0d0; Hphi = 0.0d0; Hz = 0.0d0
        psi_E_r_phi = 0.0d0; psi_E_r_z = 0.0d0; psi_E_phi_z = 0.0d0
        psi_E_phi_r = 0.0d0; psi_E_z_r = 0.0d0; psi_E_z_phi = 0.0d0
        psi_H_r_z = 0.0d0; psi_H_r_phi = 0.0d0; psi_H_phi_r = 0.0d0
        psi_H_phi_z = 0.0d0; psi_H_z_phi = 0.0d0; psi_H_z_r = 0.0d0

        call init_cpml_coefficients(nz_ref, npml_ref, ar, br, kr, ap, bp, kp, ae_z, be_z, ke_z, ah_z, bh_z, kh_z)
        nprep = source_prep_steps()

        do n = 1, nprep
            call step_cpml(nz_ref, npml_ref, Er, Ephi, Ez, Hr, Hphi, Hz, ar, br, kr, ap, bp, kp, &
                ae_z, be_z, ke_z, ah_z, bh_z, kh_z, psi_E_r_phi, psi_E_r_z, psi_E_phi_z, &
                psi_E_phi_r, psi_E_z_r, psi_E_z_phi, psi_H_r_z, psi_H_r_phi, psi_H_phi_r, &
                psi_H_phi_z, psi_H_z_phi, psi_H_z_r)
            call add_tm01_source(cname, n, Ez)
            call fill_boundaries(nz_ref, Er, Ephi, Ez, Hr, Hphi, Hz)
        end do

        deallocate(ar, br, kr, ap, bp, kp, ae_z, be_z, ke_z, ah_z, bh_z, kh_z)
        deallocate(psi_E_r_phi, psi_E_r_z, psi_E_phi_z, psi_E_phi_r, psi_E_z_r, psi_E_z_phi)
        deallocate(psi_H_r_z, psi_H_r_phi, psi_H_phi_z, psi_H_phi_r, psi_H_z_phi, psi_H_z_r)
    end subroutine prepare_source_packet


    subroutine add_tm01_source(cname, n, Ez)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: n
        real(dp), intent(inout) :: Ez(0:nr,0:nphi+1,0:nz_ref)

        integer :: i, j, ks, sgn
        real(dp) :: z_center, z_src, src, t, r, kc

        call packet_center(cname, z_center, sgn)
        z_src = z_center - real(sgn,dp)*source_distance()
        ks = nint((z_src-zmin_ref)/dz)
        if (ks < npml_ref+2 .or. ks > nz_ref-npml_ref-2) return

        t = real(n,dp)*dt
        src = packet_amp*source_time(t)
        kc = tm01_root/(real(nr,dp)*dr)
        do j = 1, nphi
        do i = 0, nr
            r = real(i,dp)*dr
            Ez(i,j,ks) = Ez(i,j,ks) + src*bessel_j0(kc*r)
        end do
        end do
        Ez(nr,1:nphi,ks) = 0.0d0
    end subroutine add_tm01_source


    integer function source_prep_steps()
        implicit none

        real(dp) :: k0, kc, beta, vg, t0, travel

        k0 = 2.0d0*pi/lambda0
        kc = tm01_root/(real(nr,dp)*dr)
        if (k0 <= kc) stop 'ERROR: lambda0 is below the TM01 cutoff for this radius.'
        beta = sqrt(k0*k0-kc*kc)
        vg = c0*beta/k0
        t0 = source_center_time(vg)
        travel = source_distance()/vg
        source_prep_steps = max(1, nint((t0+travel)/dt))
    end function source_prep_steps


    real(dp) function source_distance()
        implicit none

        real(dp) :: available, outside_compact

        available = real(max(ref_extra-2,0),dp)*dz + packet_margin
        outside_compact = packet_margin + real(npml+4,dp)*dz
        if (available <= outside_compact) then
            stop 'ERROR: ref_extra is too small for source-prepared initial field.'
        else
            source_distance = min(prep_source_distance, available)
            source_distance = max(source_distance, outside_compact)
        end if
    end function source_distance


    real(dp) function source_center_time(vg)
        implicit none

        real(dp), intent(in) :: vg

        source_center_time = 4.0d0*sigma_long/vg
    end function source_center_time


    real(dp) function source_time(t)
        implicit none

        real(dp), intent(in) :: t
        real(dp) :: k0, kc, beta, vg, t0, tau, omega

        k0 = 2.0d0*pi/lambda0
        kc = tm01_root/(real(nr,dp)*dr)
        if (k0 <= kc) stop 'ERROR: lambda0 is below the TM01 cutoff for this radius.'
        beta = sqrt(k0*k0-kc*kc)
        vg = c0*beta/k0
        omega = c0*k0
        tau = sigma_long/vg
        t0 = source_center_time(vg)
        source_time = exp(-((t-t0)/tau)**2)*cos(omega*(t-t0))
    end function source_time


    subroutine packet_center(cname, z_center, sgn)
        implicit none

        character(len=*), intent(in) :: cname
        real(dp), intent(out) :: z_center
        integer, intent(out) :: sgn

        if (trim(cname) == 'z_plus') then
            z_center = long_min_interior + packet_margin
            sgn = 1
        else if (trim(cname) == 'z_minus') then
            z_center = long_min_interior + real(n_long_interior,dp)*dz - packet_margin
            sgn = -1
        else
            write(*,'(A,A)') 'Unknown case: ', trim(cname)
            stop 2
        end if
    end subroutine packet_center


    subroutine init_probe(cname, r_probe, z_probe)
        implicit none

        character(len=*), intent(in) :: cname
        real(dp), intent(out) :: r_probe, z_probe

        r_probe = 0.35d0*real(nr,dp)*dr
        if (trim(cname) == 'z_plus') then
            z_probe = long_min_interior + probe_margin
        else
            z_probe = long_min_interior + real(n_long_interior,dp)*dz - probe_margin
        end if
    end subroutine init_probe


    subroutine probe_index(nz, zmin, r_probe, z_probe, ip, jp, kpidx)
        implicit none

        integer, intent(in) :: nz
        real(dp), intent(in) :: zmin, r_probe, z_probe
        integer, intent(out) :: ip, jp, kpidx

        ip = nint(r_probe/dr)
        jp = max(1, nphi/2)
        kpidx = nint((z_probe-zmin)/dz)
        ip = max(1, min(nr-1, ip))
        jp = max(1, min(nphi, jp))
        kpidx = max(1, min(nz-1, kpidx))
    end subroutine probe_index


    logical function should_write_snapshot(n, snap1, snap2, snap3)
        implicit none

        integer, intent(in) :: n, snap1, snap2, snap3

        if (snapshot_stride > 0) then
            should_write_snapshot = (mod(n, snapshot_stride) == 0 .or. n == nstep)
        else
            should_write_snapshot = (n == snap1 .or. n == snap2 .or. n == snap3)
        end if
    end function should_write_snapshot


    subroutine project_tm_e(nz, Ephi)
        implicit none

        integer, intent(in) :: nz
        real(dp), intent(inout) :: Ephi(0:nr,0:nphi+1,0:nz)

        Ephi = 0.0d0
    end subroutine project_tm_e


    subroutine project_tm_h(nz, Hr, Hz)
        implicit none

        integer, intent(in) :: nz
        real(dp), intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)

        Hr = 0.0d0
        Hz = 0.0d0
    end subroutine project_tm_h


    subroutine fill_boundaries(nz, Er, Ephi, Ez, Hr, Hphi, Hz)
        implicit none

        integer, intent(in) :: nz
        real(dp), intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real(dp), intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)

        call fill_e_boundaries(nz, Er, Ephi, Ez)
        call fill_h_boundaries(nz, Hr, Hphi, Hz)
    end subroutine fill_boundaries


    subroutine fill_e_boundaries(nz, Er, Ephi, Ez)
        implicit none

        integer, intent(in) :: nz
        real(dp), intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)

        call project_tm_e(nz, Ephi)
        call fill_phi(nz, Er)
        call fill_phi(nz, Ephi)
        call fill_phi(nz, Ez)
        Er(nr,:,:) = Er(nr-1,:,:)
        Ez(nr,:,:) = 0.0d0
    end subroutine fill_e_boundaries


    subroutine fill_h_boundaries(nz, Hr, Hphi, Hz)
        implicit none

        integer, intent(in) :: nz
        real(dp), intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)

        call project_tm_h(nz, Hr, Hz)
        call fill_phi(nz, Hr)
        call fill_phi(nz, Hphi)
        call fill_phi(nz, Hz)
        Hphi(nr,:,:) = Hphi(nr-1,:,:)
    end subroutine fill_h_boundaries


    subroutine fill_phi(nz, field)
        implicit none

        integer, intent(in) :: nz
        real(dp), intent(inout) :: field(0:nr,0:nphi+1,0:nz)

        field(:,0,:) = field(:,nphi,:)
        field(:,nphi+1,:) = field(:,1,:)
    end subroutine fill_phi


    real(dp) function interior_energy(nz, pml, Er, Ephi, Ez, Hr, Hphi, Hz)
        implicit none

        integer, intent(in) :: nz, pml
        real(dp), intent(in) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real(dp), intent(in) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        integer :: i, j, k
        real(dp) :: r, weight

        interior_energy = 0.0d0
        do k = pml+1, nz-pml-1
        do j = 1, nphi
        do i = 1, nr-1
            r = real(i,dp)*dr
            weight = r*dr*dphi*dz
            interior_energy = interior_energy + 0.5d0*(eps0*(Er(i,j,k)**2 + Ephi(i,j,k)**2 + Ez(i,j,k)**2) + &
                mu0*(Hr(i,j,k)**2 + Hphi(i,j,k)**2 + Hz(i,j,k)**2))*weight
        end do
        end do
        end do
    end function interior_energy


    subroutine init_cpml_coefficients(nz, pml, ar, br, kr, ap, bp, kp, ae_z, be_z, ke_z, ah_z, bh_z, kh_z)
        implicit none

        integer, intent(in) :: nz, pml
        real(dp), intent(out) :: ar(0:nr), br(0:nr), kr(0:nr)
        real(dp), intent(out) :: ap(0:nphi+1), bp(0:nphi+1), kp(0:nphi+1)
        real(dp), intent(out) :: ae_z(0:nz), be_z(0:nz), ke_z(0:nz), ah_z(0:nz), bh_z(0:nz), kh_z(0:nz)

        ar = 0.0d0; br = 1.0d0; kr = 1.0d0
        ap = 0.0d0; bp = 1.0d0; kp = 1.0d0
        call init_z_coeff(nz, pml, ae_z, be_z, ke_z, ah_z, bh_z, kh_z)
    end subroutine init_cpml_coefficients


    subroutine init_z_coeff(nz, pml, ae, be, ke, ah, bh, kh)
        implicit none

        integer, intent(in) :: nz, pml
        real(dp), intent(out) :: ae(0:nz), be(0:nz), ke(0:nz), ah(0:nz), bh(0:nz), kh(0:nz)
        integer :: k
        real(dp) :: sigma_max, dist_e, dist_h

        sigma_max = -(pml_m+1.0d0)*log(pml_R0)/(2.0d0*eta0*real(pml,dp)*dz)
        do k = 0, nz
            dist_e = 0.0d0
            if (k <= pml) then
                dist_e = real(pml+1-k,dp)/real(pml,dp)
            else if (k >= nz-pml) then
                dist_e = real(k-(nz-pml),dp)/real(pml,dp)
            end if
            dist_e = max(0.0d0, min(1.0d0, dist_e))
            call build_cpml_e_coeff(dist_e, sigma_max, ae(k), be(k), ke(k))

            dist_h = 0.0d0
            if (k < pml) then
                dist_h = real(pml-k,dp)/real(pml,dp)
            else if (k >= nz-pml) then
                dist_h = real(k-(nz-pml),dp)/real(max(1,pml-1),dp)
            end if
            dist_h = max(0.0d0, min(1.0d0, dist_h))
            call build_cpml_h_coeff(dist_h, sigma_max, ah(k), bh(k), kh(k))
        end do
    end subroutine init_z_coeff


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


    subroutine make_slice_name(cname, n, fname)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: n
        character(len=*), intent(out) :: fname

        write(fname,'("field_slice_",A,"_",I6.6,".dat")') trim(cname), n
    end subroutine make_slice_name


    subroutine write_probe(fname, cpml, ref, err_db)
        implicit none

        character(len=*), intent(in) :: fname
        real(dp), intent(in) :: cpml(0:nstep), ref(0:nstep), err_db(0:nstep)
        integer :: n, unit_id

        open(newunit=unit_id, file=fname, status='replace', action='write')
        write(unit_id,'(A)') 'n compact_Ez reference_Ez Error_dB'
        do n = 0, nstep
            write(unit_id,'(I8,3(1X,ES24.16))') n, cpml(n), ref(n), err_db(n)
        end do
        close(unit_id)
    end subroutine write_probe


    subroutine write_ez_slice(fname, nz, Ez)
        implicit none

        character(len=*), intent(in) :: fname
        integer, intent(in) :: nz
        real(dp), intent(in) :: Ez(0:nr,0:nphi+1,0:nz)
        integer :: i, k, unit_id
        integer :: jmid

        jmid = max(1, nphi/2)
        open(newunit=unit_id, file=fname, status='replace', action='write')
        write(unit_id,*) nr+1, nz+1
        do i = 0, nr
            do k = 0, nz
                write(unit_id,'(ES24.16)', advance='no') Ez(i,jmid,k)
            end do
            write(unit_id,*)
        end do
        close(unit_id)
    end subroutine write_ez_slice


    subroutine write_case_info()
        implicit none

        integer :: unit_id

        open(newunit=unit_id, file='case_info.dat', status='replace', action='write')
        write(unit_id,*) 'mode = 3d_cylindrical_m0_tm01_ez_z_cpml'
        write(unit_id,*) 'nr nphi n_long_interior =', nr, nphi, n_long_interior
        write(unit_id,*) 'nz_cpml nz_ref =', nz_cpml, nz_ref
        write(unit_id,*) 'npml npml_ref =', npml, npml_ref
        write(unit_id,*) 'ref_extra =', ref_extra
        write(unit_id,*) 'dr dphi dz =', dr, dphi, dz
        write(unit_id,*) 'dt =', dt
        write(unit_id,*) 'nstep =', nstep
        write(unit_id,*) 'late_gate =', late_gate
        write(unit_id,*) 'snapshot_stride =', snapshot_stride
        write(unit_id,*) 'long_min_interior =', long_min_interior
        write(unit_id,*) 'zmin_cpml zmin_ref =', zmin_cpml, zmin_ref
        write(unit_id,*) 'lambda0 =', lambda0
        write(unit_id,*) 'sigma_long tm01_root =', sigma_long, tm01_root
        write(unit_id,*) 'packet_margin probe_margin =', packet_margin, probe_margin
        write(unit_id,*) 'pml_m pml_R0 kappa_max alpha_max =', pml_m, pml_R0, kappa_max, alpha_max
        close(unit_id)
    end subroutine write_case_info

end program test_3d_cylindrical_wavepacket_cpml
