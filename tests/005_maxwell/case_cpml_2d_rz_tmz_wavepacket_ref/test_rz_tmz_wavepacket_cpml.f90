program test_rz_tmz_wavepacket_cpml
    use mod_E01_cpml_2d_rz_tmz
    use mod_E01_fdtd_2d_rz_tmz

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
    real(dp), parameter :: dt = 0.80d0/(c0*sqrt(1.0d0/dr**2 + 1.0d0/dz**2))

    real(dp), parameter :: sigma_long = 18.0d-3
    real(dp), parameter :: sigma_trans = 22.0d-3
    real(dp), parameter :: packet_amp = 1.0d0

    integer :: nr_interior = 136
    integer :: nz_interior = 136
    integer :: nr_ref = 356
    integer :: nz_ref = 576
    integer :: ref_extra = 200
    integer :: nstep = 450
    integer :: late_gate = 260
    integer :: snapshot_stride = 0
    integer :: npml = 14
    integer :: nr_cpml = 148
    integer :: nz_cpml = 160
    real(dp) :: zmin_cpml = -0.080d0
    real(dp) :: zmin_ref = -0.280d0
    real(dp) :: zmin_interior = -0.068d0
    real(dp) :: packet_margin = 36.0d-3
    real(dp) :: probe_margin = 24.0d-3
    real(dp) :: lambda0 = 12.0d-3
    real(dp) :: pml_m = 3.5d0
    real(dp) :: pml_R0 = 0.012d0
    real(dp) :: kappa_max = 3.0d0
    real(dp) :: alpha_max = 0.02d0
    character(len=16) :: case_filter = 'all'

    character(len=16), dimension(3), parameter :: cases = (/ &
        'z_plus          ', 'z_minus         ', 'r_plus          ' /)

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
            if (value_mm <= 0.0d0) stop 'ERROR: lambda_mm must be positive.'
            lambda0 = value_mm*1.0d-3
        end if

        call get_command_argument(2, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) npml
            if (npml < 2 .or. npml > 60) stop 'ERROR: npml must be in [2, 60].'
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
            if (int_value < 32) stop 'ERROR: n_interior must be at least 32.'
            nr_interior = int_value
            nz_interior = int_value
        end if

        call get_command_argument(9, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) value_mm
            if (value_mm <= 0.0d0) stop 'ERROR: packet_margin_mm must be positive.'
            packet_margin = value_mm*1.0d-3
            probe_margin = max(dr, packet_margin-lambda0)
        end if

        call get_command_argument(10, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 1) stop 'ERROR: nstep must be positive.'
            nstep = int_value
        end if

        call get_command_argument(11, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) stop 'ERROR: late_gate must be non-negative.'
            late_gate = int_value
        end if

        call get_command_argument(12, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) stop 'ERROR: ref_extra must be non-negative.'
            ref_extra = int_value
        end if

        call get_command_argument(13, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg,*) int_value
            if (int_value < 0) stop 'ERROR: snapshot_stride must be non-negative.'
            snapshot_stride = int_value
        end if
    end subroutine parse_args


    subroutine configure_cpml_grid()
        implicit none

        zmin_interior = -0.5d0*real(nz_interior,dp)*dz
        nr_cpml = nr_interior + npml
        nz_cpml = nz_interior + 2*npml
        nr_ref = nr_interior + ref_extra + npml_ref
        nz_ref = nz_interior + 2*ref_extra + 2*npml_ref
        zmin_cpml = zmin_interior - real(npml,dp)*dz
        zmin_ref = zmin_interior - real(ref_extra+npml_ref,dp)*dz
        if (late_gate > nstep) late_gate = nstep
        if (probe_margin >= packet_margin) stop 'ERROR: probe_margin must be smaller than packet_margin.'
        if (2.0d0*packet_margin >= real(min(nr_interior,nz_interior),dp)*dr) &
            stop 'ERROR: packet_margin is too large for n_interior.'
    end subroutine configure_cpml_grid


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

            call run_one_sim(cname, nr_cpml, nz_cpml, npml, zmin_cpml, .true., probe_cpml, e0_cpml, e1_cpml)
            call run_one_sim(cname, nr_ref, nz_ref, npml_ref, zmin_ref, .false., probe_ref, e0_ref, e1_ref)

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


    subroutine run_one_sim(cname, nr, nz, pml, zmin, write_snapshots, probe, e0, e1)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nr, nz, pml
        real(dp), intent(in) :: zmin
        logical, intent(in) :: write_snapshots
        real(dp), intent(out) :: probe(0:nstep)
        real(dp), intent(out) :: e0, e1

        real(dp), allocatable :: Er(:,:), Ez(:,:), Ha(:,:)
        real(dp), allocatable :: ae_r(:), be_r(:), ke_r(:)
        real(dp), allocatable :: ae_z(:), be_z(:), ke_z(:)
        real(dp), allocatable :: ah_r(:), bh_r(:), kh_r(:)
        real(dp), allocatable :: ah_z(:), bh_z(:), kh_z(:)
        real(dp), allocatable :: psi_ez_r(:,:), psi_er_z(:,:), psi_ha_r(:,:), psi_ha_z(:,:)
        integer :: n, ip, kp, snap1, snap2
        real(dp) :: r_probe, z_probe
        character(len=80) :: snap_name

        allocate(Er(0:nr-1,0:nz-1), Ez(0:nr-1,0:nz-1), Ha(0:nr-1,0:nz-1))
        allocate(ae_r(0:nr-1), be_r(0:nr-1), ke_r(0:nr-1))
        allocate(ae_z(0:nz-1), be_z(0:nz-1), ke_z(0:nz-1))
        allocate(ah_r(0:nr-1), bh_r(0:nr-1), kh_r(0:nr-1))
        allocate(ah_z(0:nz-1), bh_z(0:nz-1), kh_z(0:nz-1))
        allocate(psi_ez_r(0:nr-1,0:nz-1), psi_er_z(0:nr-1,0:nz-1))
        allocate(psi_ha_r(0:nr-1,0:nz-1), psi_ha_z(0:nr-1,0:nz-1))

        Er = 0.0d0
        Ez = 0.0d0
        Ha = 0.0d0
        psi_ez_r = 0.0d0
        psi_er_z = 0.0d0
        psi_ha_r = 0.0d0
        psi_ha_z = 0.0d0

        call init_wavepacket(cname, nr, nz, zmin, Er, Ez, Ha)
        call init_probe(cname, r_probe, z_probe)
        call probe_index(nr, nz, zmin, r_probe, z_probe, ip, kp)
        call init_cpml_coefficients(nr, nz, pml, ae_r, be_r, ke_r, ae_z, be_z, ke_z, &
            ah_r, bh_r, kh_r, ah_z, bh_z, kh_z)

        e0 = interior_energy(nr, nz, pml, Er, Ez, Ha)
        probe(0) = probe_field(cname, Er, Ez, ip, kp)
        if (write_snapshots) then
            call make_snapshot_name(cname, 0, snap_name)
            call write_field('er_'//trim(snap_name), nr, nz, Er)
            call write_field('ez_'//trim(snap_name), nr, nz, Ez)
            call write_field('ha_'//trim(snap_name), nr, nz, Ha)
        end if

        snap1 = max(1, nstep/3)
        snap2 = max(snap1+1, (2*nstep)/3)

        do n = 1, nstep
            call step_cpml(nr, nz, pml, Er, Ez, Ha, ae_r, be_r, ke_r, ae_z, be_z, ke_z, &
                ah_r, bh_r, kh_r, ah_z, bh_z, kh_z, psi_ez_r, psi_er_z, psi_ha_r, psi_ha_z)

            probe(n) = probe_field(cname, Er, Ez, ip, kp)

            if (write_snapshots) then
                if (should_write_snapshot(n, snap1, snap2)) then
                    call make_snapshot_name(cname, n, snap_name)
                    call write_field('er_'//trim(snap_name), nr, nz, Er)
                    call write_field('ez_'//trim(snap_name), nr, nz, Ez)
                    call write_field('ha_'//trim(snap_name), nr, nz, Ha)
                end if
            end if
        end do

        e1 = interior_energy(nr, nz, pml, Er, Ez, Ha)
        if (write_snapshots) then
            call write_field('er_final_'//trim(cname)//'.dat', nr, nz, Er)
            call write_field('ez_final_'//trim(cname)//'.dat', nr, nz, Ez)
            call write_field('ha_final_'//trim(cname)//'.dat', nr, nz, Ha)
        end if

        deallocate(Er, Ez, Ha)
        deallocate(ae_r, be_r, ke_r, ae_z, be_z, ke_z)
        deallocate(ah_r, bh_r, kh_r, ah_z, bh_z, kh_z)
        deallocate(psi_ez_r, psi_er_z, psi_ha_r, psi_ha_z)
    end subroutine run_one_sim


    subroutine step_cpml(nr, nz, pml, Er, Ez, Ha, ae_r, be_r, ke_r, ae_z, be_z, ke_z, &
        ah_r, bh_r, kh_r, ah_z, bh_z, kh_z, psi_ez_r, psi_er_z, psi_ha_r, psi_ha_z)
        implicit none

        integer, intent(in) :: nr, nz, pml
        real(dp), intent(inout) :: Er(0:nr-1,0:nz-1), Ez(0:nr-1,0:nz-1), Ha(0:nr-1,0:nz-1)
        real(dp), intent(in) :: ae_r(0:nr-1), be_r(0:nr-1), ke_r(0:nr-1)
        real(dp), intent(in) :: ae_z(0:nz-1), be_z(0:nz-1), ke_z(0:nz-1)
        real(dp), intent(in) :: ah_r(0:nr-1), bh_r(0:nr-1), kh_r(0:nr-1)
        real(dp), intent(in) :: ah_z(0:nz-1), bh_z(0:nz-1), kh_z(0:nz-1)
        real(dp), intent(inout) :: psi_ez_r(0:nr-1,0:nz-1), psi_er_z(0:nr-1,0:nz-1)
        real(dp), intent(inout) :: psi_ha_r(0:nr-1,0:nz-1), psi_ha_z(0:nr-1,0:nz-1)

        call sub_E01_fdtd_2d_rz_tmz_H(0,nr-1,0,nz-1, &
            0,nr-pml-2,pml,nz-pml-2, Ha,Er,Ez,dt,dr,dz,mu0)

        call sub_E01_cpml_2d_rz_tmz_H(0,nr-1,0,nz-1, &
            0,nr-2,0,pml-1, Ha,Er,Ez,dt,dr,dz,mu0, &
            ah_r,bh_r,kh_r,ah_z,bh_z,kh_z,psi_ha_r,psi_ha_z)
        call sub_E01_cpml_2d_rz_tmz_H(0,nr-1,0,nz-1, &
            0,nr-2,nz-pml-1,nz-2, Ha,Er,Ez,dt,dr,dz,mu0, &
            ah_r,bh_r,kh_r,ah_z,bh_z,kh_z,psi_ha_r,psi_ha_z)
        call sub_E01_cpml_2d_rz_tmz_H(0,nr-1,0,nz-1, &
            nr-pml-1,nr-2,pml,nz-pml-2, Ha,Er,Ez,dt,dr,dz,mu0, &
            ah_r,bh_r,kh_r,ah_z,bh_z,kh_z,psi_ha_r,psi_ha_z)

        call sub_E01_fdtd_2d_rz_tmz_E(0,nr-1,0,nz-1, &
            0,nr-pml-1,pml,nz-pml-1, Ha,Er,Ez,dt,dr,dz,eps0)
        call sub_E01_fdtd_2d_rz_tmz_E(0,nr-1,0,nz-1, &
            0,0,1,pml-1, Ha,Er,Ez,dt,dr,dz,eps0)
        call sub_E01_fdtd_2d_rz_tmz_E(0,nr-1,0,nz-1, &
            0,0,nz-pml,nz-2, Ha,Er,Ez,dt,dr,dz,eps0)

        call sub_E01_cpml_2d_rz_tmz_E(0,nr-1,0,nz-1, &
            1,nr-2,1,pml-1, Ha,Er,Ez,dt,dr,dz,eps0, &
            ae_r,be_r,ke_r,ae_z,be_z,ke_z,psi_ez_r,psi_er_z)
        call sub_E01_cpml_2d_rz_tmz_E(0,nr-1,0,nz-1, &
            1,nr-2,nz-pml,nz-2, Ha,Er,Ez,dt,dr,dz,eps0, &
            ae_r,be_r,ke_r,ae_z,be_z,ke_z,psi_ez_r,psi_er_z)
        call sub_E01_cpml_2d_rz_tmz_E(0,nr-1,0,nz-1, &
            nr-pml,nr-2,pml,nz-pml-1, Ha,Er,Ez,dt,dr,dz,eps0, &
            ae_r,be_r,ke_r,ae_z,be_z,ke_z,psi_ez_r,psi_er_z)
    end subroutine step_cpml


    subroutine init_wavepacket(cname, nr, nz, zmin, Er, Ez, Ha)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: nr, nz
        real(dp), intent(in) :: zmin
        real(dp), intent(out) :: Er(0:nr-1,0:nz-1), Ez(0:nr-1,0:nz-1), Ha(0:nr-1,0:nz-1)

        integer :: i, k, sgn
        real(dp) :: r_er, z_er, r_ez, z_ez, r_ha, z_ha, r_center, z_center
        real(dp) :: q, qh, trans, cdt2

        Er = 0.0d0
        Ez = 0.0d0
        Ha = 0.0d0
        cdt2 = 0.5d0*c0*dt

        call packet_center(cname, r_center, z_center, sgn)

        do k = 0, nz-1
        do i = 0, nr-1
            r_er = (real(i,dp)+0.5d0)*dr
            z_er = zmin + real(k,dp)*dz
            r_ez = real(i,dp)*dr
            z_ez = zmin + (real(k,dp)+0.5d0)*dz
            r_ha = (real(i,dp)+0.5d0)*dr
            z_ha = zmin + (real(k,dp)+0.5d0)*dz

            if (index(cname, 'z_') == 1) then
                q = real(sgn,dp)*(z_er-z_center)
                trans = r_er-r_center
                Er(i,k) = packet_amp*packet_shape(q, trans)

                qh = real(sgn,dp)*(z_ha-z_center) + cdt2
                Ha(i,k) = real(sgn,dp)/eta0*packet_amp*packet_shape(qh, r_ha-r_center)
            else
                q = real(sgn,dp)*(r_ez-r_center)
                trans = z_ez-z_center
                Ez(i,k) = packet_amp*packet_shape(q, trans)

                qh = real(sgn,dp)*(r_ha-r_center) + cdt2
                Ha(i,k) = -real(sgn,dp)/eta0*packet_amp*packet_shape(qh, z_ha-z_center)
            end if
        end do
        end do
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

        r_center = 0.5d0*real(nr_interior,dp)*dr
        z_center = zmin_interior + 0.5d0*real(nz_interior,dp)*dz
        sgn = 1

        select case (trim(cname))
        case ('z_plus')
            z_center = zmin_interior + packet_margin
            sgn = 1
        case ('z_minus')
            z_center = zmin_interior + real(nz_interior,dp)*dz - packet_margin
            sgn = -1
        case ('r_plus')
            r_center = packet_margin
            sgn = 1
        case default
            write(*,'(A,A)') 'Unknown case: ', trim(cname)
            stop 2
        end select
    end subroutine packet_center


    subroutine init_probe(cname, r_probe, z_probe)
        implicit none

        character(len=*), intent(in) :: cname
        real(dp), intent(out) :: r_probe, z_probe

        r_probe = 0.5d0*real(nr_interior,dp)*dr
        z_probe = zmin_interior + 0.5d0*real(nz_interior,dp)*dz

        select case (trim(cname))
        case ('z_plus')
            z_probe = zmin_interior + probe_margin
        case ('z_minus')
            z_probe = zmin_interior + real(nz_interior,dp)*dz - probe_margin
        case ('r_plus')
            r_probe = probe_margin
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


    subroutine probe_index(nr, nz, zmin, r_probe, z_probe, ip, kp)
        implicit none

        integer, intent(in) :: nr, nz
        real(dp), intent(in) :: zmin, r_probe, z_probe
        integer, intent(out) :: ip, kp

        ip = nint(r_probe/dr)
        kp = nint((z_probe-zmin)/dz)
        ip = max(1, min(nr-2, ip))
        kp = max(1, min(nz-2, kp))
    end subroutine probe_index


    real(dp) function probe_field(cname, Er, Ez, ip, kp)
        implicit none

        character(len=*), intent(in) :: cname
        integer, intent(in) :: ip, kp
        real(dp), intent(in) :: Er(:,:), Ez(:,:)

        if (index(cname, 'z_') == 1) then
            probe_field = Er(ip,kp)
        else
            probe_field = Ez(ip,kp)
        end if
    end function probe_field


    real(dp) function interior_energy(nr, nz, pml, Er, Ez, Ha)
        implicit none

        integer, intent(in) :: nr, nz, pml
        real(dp), intent(in) :: Er(0:nr-1,0:nz-1), Ez(0:nr-1,0:nz-1), Ha(0:nr-1,0:nz-1)
        integer :: i, k

        interior_energy = 0.0d0
        do k = pml, nz-pml-1
        do i = 0, nr-pml-1
            interior_energy = interior_energy + 0.5d0*(eps0*(Er(i,k)**2 + Ez(i,k)**2) + &
                mu0*Ha(i,k)**2)*dr*dz
        end do
        end do
    end function interior_energy


    subroutine init_cpml_coefficients(nr, nz, pml, ae_r, be_r, ke_r, ae_z, be_z, ke_z, &
        ah_r, bh_r, kh_r, ah_z, bh_z, kh_z)
        implicit none

        integer, intent(in) :: nr, nz, pml
        real(dp), intent(out) :: ae_r(0:nr-1), be_r(0:nr-1), ke_r(0:nr-1)
        real(dp), intent(out) :: ae_z(0:nz-1), be_z(0:nz-1), ke_z(0:nz-1)
        real(dp), intent(out) :: ah_r(0:nr-1), bh_r(0:nr-1), kh_r(0:nr-1)
        real(dp), intent(out) :: ah_z(0:nz-1), bh_z(0:nz-1), kh_z(0:nz-1)

        call init_r_coeff(nr, pml, ae_r, be_r, ke_r, ah_r, bh_r, kh_r)
        call init_z_coeff(nz, pml, ae_z, be_z, ke_z, ah_z, bh_z, kh_z)
    end subroutine init_cpml_coefficients


    subroutine init_r_coeff(nr, pml, ae, be, ke, ah, bh, kh)
        implicit none

        integer, intent(in) :: nr, pml
        real(dp), intent(out) :: ae(0:nr-1), be(0:nr-1), ke(0:nr-1), ah(0:nr-1), bh(0:nr-1), kh(0:nr-1)
        integer :: i
        real(dp) :: sigma_max, dist_e, dist_h

        sigma_max = -(pml_m+1.0d0)*log(pml_R0)/(2.0d0*eta0*real(pml,dp)*dr)
        do i = 0, nr-1
            dist_e = 0.0d0
            if (i >= nr-pml) dist_e = real(i-(nr-pml),dp)/real(max(1,pml-1),dp)
            dist_e = max(0.0d0, min(1.0d0, dist_e))
            call build_cpml_e_coeff(dist_e, sigma_max, ae(i), be(i), ke(i))

            dist_h = 0.0d0
            if (i >= nr-pml-1) dist_h = real(i-(nr-pml-1),dp)/real(max(1,pml-1),dp)
            dist_h = max(0.0d0, min(1.0d0, dist_h))
            call build_cpml_h_coeff(dist_h, sigma_max, ah(i), bh(i), kh(i))
        end do
    end subroutine init_r_coeff


    subroutine init_z_coeff(nz, pml, ae, be, ke, ah, bh, kh)
        implicit none

        integer, intent(in) :: nz, pml
        real(dp), intent(out) :: ae(0:nz-1), be(0:nz-1), ke(0:nz-1), ah(0:nz-1), bh(0:nz-1), kh(0:nz-1)
        integer :: k
        real(dp) :: sigma_max, dist_e, dist_h

        sigma_max = -(pml_m+1.0d0)*log(pml_R0)/(2.0d0*eta0*real(pml,dp)*dz)
        do k = 0, nz-1
            dist_e = 0.0d0
            if (k < pml) then
                dist_e = real(pml-1-k,dp)/real(max(1,pml-1),dp)
            else if (k >= nz-pml) then
                dist_e = real(k-(nz-pml),dp)/real(max(1,pml-1),dp)
            end if
            dist_e = max(0.0d0, min(1.0d0, dist_e))
            call build_cpml_e_coeff(dist_e, sigma_max, ae(k), be(k), ke(k))

            dist_h = 0.0d0
            if (k < pml) then
                dist_h = real(pml-1-k,dp)/real(max(1,pml-1),dp)
            else if (k >= nz-pml-1) then
                dist_h = real(k-(nz-pml-1),dp)/real(max(1,pml-1),dp)
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
        write(unit_id,*) 'mode = rz_tmz_er_ez_ha'
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
        write(unit_id,*) 'zmin_interior =', zmin_interior
        write(unit_id,*) 'zmin_cpml =', zmin_cpml
        write(unit_id,*) 'zmin_ref =', zmin_ref
        write(unit_id,*) 'lambda0 =', lambda0
        write(unit_id,*) 'sigma_long sigma_trans =', sigma_long, sigma_trans
        write(unit_id,*) 'packet_margin probe_margin =', packet_margin, probe_margin
        write(unit_id,*) 'pml_m pml_R0 kappa_max alpha_max =', pml_m, pml_R0, kappa_max, alpha_max
        close(unit_id)
    end subroutine write_case_info

end program test_rz_tmz_wavepacket_cpml
