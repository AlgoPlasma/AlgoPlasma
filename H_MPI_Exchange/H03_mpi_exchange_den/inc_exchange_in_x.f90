! If MPI split > 1.
if (domain_split(1)>1) then

    jj = 0
    kk = 0

    ! The first dimension direction, so the arrays sent and received are data
    ! in the plane perpendicular to the direction vector.
    allocate(buf_send(il(2):iu(2),il(3):iu(3)))
    allocate(buf_recv(il(2):iu(2),il(3):iu(3)))
    buf_send = 0.0
    buf_recv = 0.0

    ! For odd i, send then recv.
    if ( mod(i,2)==1 ) then

        if ( ijk_to_rank(i+1,j,k)/=-1 ) then ! with neighboring subregion downstream
            ii = 1
            buf_send(:,:) = den(iu(1),il(2):iu(2),il(3):iu(3))
#           include "inc_send_recv.f90"
            den(iu(1),il(2):iu(2),il(3):iu(3)) = &
            den(iu(1),il(2):iu(2),il(3):iu(3)) + buf_recv(:,:)
        end if

        if ( ijk_to_rank(i-1,j,k)/=-1 ) then  ! with neighboring subregion upstream
            ii = -1
            buf_send(:,:) = den(il(1),il(2):iu(2),il(3):iu(3))
#           include "inc_send_recv.f90"
            den(il(1),il(2):iu(2),il(3):iu(3)) = &
            den(il(1),il(2):iu(2),il(3):iu(3)) + buf_recv(:,:)
        end if

    ! For even i, recv then send.
    else

        if ( ijk_to_rank(i-1,j,k)/=-1 ) then
            ii = -1
            buf_send(:,:) = den(il(1),il(2):iu(2),il(3):iu(3))
#           include "inc_recv_send.f90"
            den(il(1),il(2):iu(2),il(3):iu(3)) = &
            den(il(1),il(2):iu(2),il(3):iu(3)) + buf_recv(:,:)
        end if

        if ( ijk_to_rank(i+1,j,k)/=-1 ) then
            ii = 1
            buf_send(:,:) = den(iu(1),il(2):iu(2),il(3):iu(3))
#           include "inc_recv_send.f90"
            den(iu(1),il(2):iu(2),il(3):iu(3)) = &
            den(iu(1),il(2):iu(2),il(3):iu(3)) + buf_recv(:,:)
        end if

    end if

    deallocate(buf_send,buf_recv)

end if
