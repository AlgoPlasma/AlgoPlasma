! Radial-first corner convention: each crossing must form a connected path.
program test_J01_corner_crossings
    use mod_J01_neutral_free_molecular_2Drz
    implicit none
    type(fm_tally_2drz_type) :: tally
    integer :: sr, sz, i, k, ni, nk, ft(4,2,2), failures
    real :: r,z,ur,uz, expected_r(1,2), expected_z(2,1), net(2,2), expected(2,2)
    logical :: escaped,truncated
    failures = 0
    do sr = -1, 1, 2
        do sz = -1, 1, 2
            if (allocated(tally%residence)) then
                deallocate(tally%residence,tally%moment_r,tally%moment_z, &
                    tally%count_r,tally%count_z,tally%boundary_count)
            end if
            call sub_J01_initialize_fm_tally(2,2,tally)
            ft = J01_FACE_OPEN
            ft(J01_R_HI,1,:) = J01_FACE_INTERIOR
            ft(J01_R_LO,2,:) = J01_FACE_INTERIOR
            ft(J01_Z_HI,:,1) = J01_FACE_INTERIOR
            ft(J01_Z_LO,:,2) = J01_FACE_INTERIOR
            i = 1
            k = 1
            if (sr < 0) i = 2
            if (sz < 0) k = 2
            ni = i+sr
            nk = k+sz
            r = real(i)+0.5
            z = real(k)-0.5
            ur = real(sr)
            uz = real(sz)
            call sub_J01_trace_fm_history([1.0,2.0,3.0],[0.0,1.0,2.0], &
                reshape([.true.,.true.,.true.,.true.],[2,2]),ft,0.0,1.0,1,1.e-9,1.e-9, &
                r,z,ur,uz,tally,escaped,truncated)
            expected_r = 0.0
            expected_z = 0.0
            expected_r(1,k) = real(sr)
            expected_z(ni,1) = real(sz)
            call check(maxval(abs(tally%count_r-expected_r)) < 1.e-12, 'radial crossing')
            call check(maxval(abs(tally%count_z-expected_z)) < 1.e-12, 'axial crossing uses new cell')
            net = 0.0
            net(1,:) = net(1,:)-tally%count_r(1,:)
            net(2,:) = net(2,:)+tally%count_r(1,:)
            net(:,1) = net(:,1)-tally%count_z(:,1)
            net(:,2) = net(:,2)+tally%count_z(:,1)
            expected = 0.0
            expected(i,k) = -1.0
            expected(ni,nk) = 1.0
            call check(maxval(abs(net-expected)) < 1.e-12, 'cellwise particle balance')
            call check(abs(sum(tally%residence)-0.5) < 1.e-12, 'no extra corner residence')
            write(*, '(a,2i3,4es24.15)') 'VALUE: corner signs; radial/axial/balance/residence errors: ', sr, sz, &
                maxval(abs(tally%count_r-expected_r)), maxval(abs(tally%count_z-expected_z)), &
                maxval(abs(net-expected)), abs(sum(tally%residence)-0.5)
        end do
    end do
    ! At a stepped boundary, use the axial face of the newly entered cell.
    do i = J01_FACE_OPEN, J01_FACE_WALL
        tally%residence = 0.0
        tally%moment_r = 0.0
        tally%moment_z = 0.0
        tally%count_r = 0.0
        tally%count_z = 0.0
        tally%boundary_count = 0.0
        ft(J01_Z_HI,2,1) = i
        r = 1.5
        z = 0.5
        ur = 1.0
        uz = 1.0
        call sub_J01_trace_fm_history([1.0,2.0,3.0],[0.0,1.0,2.0], &
            reshape([.true.,.true.,.true.,.false.],[2,2]),ft,0.0,1.0,1,1.e-9,1.e-9, &
            r,z,ur,uz,tally,escaped,truncated)
        call check(abs(tally%count_r(1,1)-1.0) < 1.e-12, 'step corner enters radial neighbour')
        call check(maxval(abs(tally%count_z)) < 1.e-12, 'step corner has no false axial internal crossing')
        write(*, '(a,i3,2l3,3es24.15)') 'VALUE: step face type/escaped/truncated/r count/z count/uz: ', &
            i, escaped, truncated, tally%count_r(1,1), maxval(abs(tally%count_z)), uz
        if (i == J01_FACE_OPEN) then
            call check(escaped .and. abs(tally%boundary_count(J01_Z_HI,2,1)-1.0) < 1.e-12, &
                'step corner exits new cell open face')
        else
            call check(truncated .and. uz < 0.0, 'step corner reflects at new cell wall')
        end if
    end do
    call check_near_corner()
    call check_near_corner_orders()
    if (failures > 0) error stop 1
    print *, 'RESULT: PASS'
contains
    ! Two distinct crossings less than 1e-12 s apart must not be counted twice.
    subroutine check_near_corner()
        type(fm_tally_2drz_type) :: sample
        integer :: faces(4,2,2)
        real :: rr, zz, vr, vz, balance(2,2), target(2,2), err
        logical :: escaped_case, truncated_case
        faces = J01_FACE_OPEN
        faces(J01_R_HI,1,:) = J01_FACE_INTERIOR
        faces(J01_R_LO,2,:) = J01_FACE_INTERIOR
        faces(J01_Z_HI,:,1) = J01_FACE_INTERIOR
        faces(J01_Z_LO,:,2) = J01_FACE_INTERIOR
        call sub_J01_initialize_fm_tally(2,2,sample)
        rr = 0.0015
        zz = 0.0004999995
        vr = 1000.0
        vz = 1000.0
        call sub_J01_trace_fm_history([0.001,0.002,0.003],[0.0,0.001,0.002], &
            reshape([.true.,.true.,.true.,.true.],[2,2]),faces,0.0,1.0,10,1.e-12,1.e-12, &
            rr,zz,vr,vz,sample,escaped_case,truncated_case)
        call check(escaped_case .and. .not. truncated_case, 'near corner completes its history')
        call check(maxval(abs(sample%count_r(1,:)-[1.0,0.0])) < 1.e-12, 'near corner radial count')
        call check(maxval(abs(sample%count_z(:,1)-[0.0,1.0])) < 1.e-12, 'near corner axial count once')
        balance(1,:) = -sample%count_r(1,:)
        balance(2,:) = sample%count_r(1,:)
        balance(:,1) = balance(:,1)-sample%count_z(:,1)
        balance(:,2) = balance(:,2)+sample%count_z(:,1)
        balance = balance+sample%boundary_count(J01_R_LO,:,:)-sample%boundary_count(J01_R_HI,:,:) &
                         +sample%boundary_count(J01_Z_LO,:,:)-sample%boundary_count(J01_Z_HI,:,:)
        target = 0.0
        target(1,1) = -1.0
        err = maxval(abs(balance-target))
        call check(err < 1.e-12, 'near corner has no artificial cell source or sink')
        call check(abs(sum(sample%residence)-1.5e-6) < 1.e-14, 'near corner residence time')
        write(*,'(a,4es24.15)') 'VALUE: near corner axial count/expected/balance error/residence: ', &
            sample%count_z(2,1),1.0,err,sum(sample%residence)
    end subroutine check_near_corner

    ! Analytical straight paths: both face orders, all signs and two time scales.
    subroutine check_near_corner_orders()
        type(fm_tally_2drz_type) :: sample
        integer :: faces(4,2,2), ir, iz, jr, jz, sign_r, sign_z, order, speed_case, cases
        real :: rr, zz, vr, vz, speed, length, delta, offset, exact_time, time_error
        real :: radial(1,2), axial(2,1), balance(2,2), target(2,2), max_count_error, max_time_error
        logical :: escaped_case, truncated_case
        length = 1.e-3
        delta = 5.e-7*length
        offset = 1.e-12
        faces = J01_FACE_OPEN
        faces(J01_R_HI,1,:) = J01_FACE_INTERIOR
        faces(J01_R_LO,2,:) = J01_FACE_INTERIOR
        faces(J01_Z_HI,:,1) = J01_FACE_INTERIOR
        faces(J01_Z_LO,:,2) = J01_FACE_INTERIOR
        cases = 0
        max_count_error = 0.0
        max_time_error = 0.0
        do speed_case = 1, 2
            speed = 1.e3
            if (speed_case == 2) speed = 1.e7
            do order = -1, 1, 2
                do sign_r = -1, 1, 2
                    do sign_z = -1, 1, 2
                        call sub_J01_initialize_fm_tally(2,2,sample)
                        ir = merge(1,2,sign_r > 0)
                        iz = merge(1,2,sign_z > 0)
                        jr = 3-ir
                        jz = 3-iz
                        rr = (real(ir)+0.5)*length
                        zz = (real(iz)-0.5)*length+real(order*sign_z)*delta
                        vr = real(sign_r)*speed
                        vz = real(sign_z)*speed
                        call sub_J01_trace_fm_history(length*[1.0,2.0,3.0],length*[0.0,1.0,2.0], &
                            reshape([.true.,.true.,.true.,.true.],[2,2]),faces,0.0,1.0,10,offset,offset, &
                            rr,zz,vr,vz,sample,escaped_case,truncated_case)
                        radial = 0.0
                        axial = 0.0
                        if (order < 0) then
                            radial(1,iz) = real(sign_r)
                            axial(jr,1) = real(sign_z)
                            exact_time = 1.5*length/speed
                        else
                            axial(ir,1) = real(sign_z)
                            radial(1,jz) = real(sign_r)
                            exact_time = (1.5*length-delta)/speed
                        end if
                        balance(1,:) = -sample%count_r(1,:)
                        balance(2,:) = sample%count_r(1,:)
                        balance(:,1) = balance(:,1)-sample%count_z(:,1)
                        balance(:,2) = balance(:,2)+sample%count_z(:,1)
                        balance = balance+sample%boundary_count(J01_R_LO,:,:)-sample%boundary_count(J01_R_HI,:,:) &
                                         +sample%boundary_count(J01_Z_LO,:,:)-sample%boundary_count(J01_Z_HI,:,:)
                        target = 0.0
                        target(ir,iz) = -1.0
                        max_count_error = max(max_count_error,maxval(abs(sample%count_r-radial)), &
                            maxval(abs(sample%count_z-axial)),maxval(abs(balance-target)))
                        time_error = abs(sum(sample%residence)-exact_time)
                        max_time_error = max(max_time_error,time_error/exact_time)
                        call check(escaped_case .and. .not. truncated_case, 'ordered near corner escapes')
                        call check(abs(sum(abs(sample%boundary_count))-1.0) < 1.e-12, 'exactly one exit')
                        call check(time_error <= 4.0*offset/speed+128.0*epsilon(1.0)*exact_time, &
                            'ordered near corner residence agrees within positioning offsets')
                        cases = cases+1
                    end do
                end do
            end do
        end do
        call check(max_count_error < 1.e-12, 'both near-corner orders preserve signed cell balance')
        write(*,'(a,i3,2es24.15)') 'VALUE: near corner cases/count-balance error/max relative residence error: ', &
            cases,max_count_error,max_time_error
    end subroutine check_near_corner_orders

    subroutine check(ok,label)
        logical,intent(in) :: ok
        character(*),intent(in) :: label
        if (.not. ok) then
            print *, 'FAIL: ',label,' signs=',sr,sz
            failures = failures+1
        end if
    end subroutine
end program
