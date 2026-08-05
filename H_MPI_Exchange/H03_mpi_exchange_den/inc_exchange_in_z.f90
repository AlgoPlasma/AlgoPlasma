! If MPI split > 1.
if (domain_split(3)>1) then

    ii = 0
    jj = 0

    allocate(buf_send(il(1):iu(1),il(2):iu(2)))
    allocate(buf_recv(il(1):iu(1),il(2):iu(2)))
    buf_send = 0.0
    buf_recv = 0.0

    ! For odd k, send then recv.
    if ( mod(k,2)==1 ) then

        if ( ijk_to_rank(i,j,k+1)/=-1 ) then
            kk = 1
            buf_send(:,:) = den(il(1):iu(1),il(2):iu(2),iu(3))
#           include "inc_send_recv.f90"
            den(il(1):iu(1),il(2):iu(2),iu(3)) = &
            den(il(1):iu(1),il(2):iu(2),iu(3)) + buf_recv(:,:)
        end if

        if ( ijk_to_rank(i,j,k-1)/=-1 ) then
            kk = -1
            buf_send(:,:) = den(il(1):iu(1),il(2):iu(2),il(3))
#           include "inc_send_recv.f90"
            den(il(1):iu(1),il(2):iu(2),il(3)) = &
            den(il(1):iu(1),il(2):iu(2),il(3)) + buf_recv(:,:)
        end if

    ! For even k, recv then send.
    else

        if ( ijk_to_rank(i,j,k-1)/=-1 ) then
            kk = -1
            buf_send(:,:) = den(il(1):iu(1),il(2):iu(2),il(3))
#           include "inc_recv_send.f90"
            den(il(1):iu(1),il(2):iu(2),il(3)) = &
            den(il(1):iu(1),il(2):iu(2),il(3)) + buf_recv(:,:)
        end if

        if ( ijk_to_rank(i,j,k+1)/=-1 ) then
            kk = 1
            buf_send(:,:) = den(il(1):iu(1),il(2):iu(2),iu(3))
#           include "inc_recv_send.f90"
            den(il(1):iu(1),il(2):iu(2),iu(3)) = &
            den(il(1):iu(1),il(2):iu(2),iu(3)) + buf_recv(:,:)
        end if

    end if

    deallocate(buf_send,buf_recv)

end if
