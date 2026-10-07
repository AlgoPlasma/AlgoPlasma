! A single public sweep handles prescribed inlet data without a dummy old field.
program test_J02_unified_sweep
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geo
    type(sn_quadrature_type) :: quad
    type(sn_boundary_2drz_type) :: boundary
    real, allocatable :: sigma(:,:,:), inlet(:), psi(:,:,:,:), full(:,:,:,:)
    real, allocatable :: ref(:,:,:,:), fin(:,:,:), fout(:,:,:)
    real :: incoming, outgoing
    integer :: ierr, m, fd, fi, fk

    call sub_J02_initialize_mesh([1.0,2.0,3.0], [0.0,1.0,2.0], &
        reshape([.true.,.true.,.true.,.true.],[2,2]), mesh, ierr)
    call sub_J02_build_geometry(mesh, 1.0, geo, ierr)
    call sub_J02_build_phase_quadrature(8, 2, 'midpoint', 4.0, quad, ierr)
    call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
    allocate(sigma(2,2,quad%n_dir), inlet(quad%n_dir), full(4,2,2,quad%n_dir))
    sigma = 0.0
    inlet = merge(1.0,0.0,quad%eta > 0.0)
    full = 0.0
    do m = 1, quad%n_dir
        full(SN_Z_LO,:,1,m) = inlet(m)
    end do
    call sub_J02_sweep(mesh, geo, quad, sigma, boundary, psi, ierr, zlo_inflow=inlet)
    if (ierr /= SN_SUCCESS) error stop 'compact open sweep requires unnecessary wall state'
    call sub_J02_reconstruct_open_boundary_fluxes(mesh,geo,boundary,quad,psi, &
        inflow_flux=fin,outflow_flux=fout,ierr=ierr,zlo_inflow=inlet)
    if (ierr /= SN_SUCCESS) error stop 'flux reconstruction failed'
    incoming = sum(fin(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
    outgoing = -sum(fout(SN_R_LO,1,:)*geo%area_r_lo(1,:)) &
        +sum(fout(SN_R_HI,2,:)*geo%area_r_hi(2,:)) &
        -sum(fout(SN_Z_LO,:,1)*geo%area_z_lo(:,1)) &
        +sum(fout(SN_Z_HI,:,2)*geo%area_z_hi(:,2))
    if (incoming <= 0.0) error stop 'nonzero inlet created no incoming flux'
    if (abs(outgoing-incoming)/incoming > 1.e-12) error stop 'open sweep lost particles'
    ref = psi
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=full)
    if (ierr /= SN_SUCCESS) error stop 'full inlet sweep failed'
    if (maxval(abs(psi-ref)) > 1.e-12) error stop 'inlet representation changed solution'
    write(*,'(a,4es24.15)') 'VALUE: open sweep incoming/outgoing/relative balance/compact difference: ', &
        incoming,outgoing,abs(outgoing-incoming)/incoming,maxval(abs(psi-ref))
    print *, 'PASS: open sweep needs no old field and preserves particle balance'

    boundary%face_z_hi(:,2) = SN_FACE_WALL
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,zlo_inflow=inlet)
    if (ierr /= SN_ERR_REFLECTION_INPUT) error stop 'wall without old state accepted'
    write(*,'(a,2i8)') 'STATUS: missing wall state actual/expected: ',ierr,SN_ERR_REFLECTION_INPUT
    boundary%face_z_hi(:,2) = SN_FACE_OPEN
    boundary%face_r_lo(1,1) = -1
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,zlo_inflow=inlet, &
        failed_direction=fd,failed_i=fi,failed_k=fk)
    if (ierr /= SN_ERR_SWEEP_FACE_TOPOLOGY) error stop 'invalid face type accepted'
    if (fi /= 1 .or. fk /= 1) error stop 'invalid face location missing'
    write(*,'(a,5i8)') 'STATUS: invalid topology ierr/expected/direction/i/k: ', &
        ierr,SN_ERR_SWEEP_FACE_TOPOLOGY,fd,fi,fk
    print *, 'PASS: incomplete wall state and invalid face type are rejected'
    print *, 'RESULT: PASS'
end program test_J02_unified_sweep
