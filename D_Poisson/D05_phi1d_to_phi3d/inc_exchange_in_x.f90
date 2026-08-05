! If MPI split > 1.
if (domain_split(1)>1) then

    jj = 0
    kk = 0

    allocate(buf_send(il(2)-1:iu(2)+1,il(3)-1:iu(3)+1))
    allocate(buf_recv(il(2)-1:iu(2)+1,il(3)-1:iu(3)+1))
    buf_send = 0.0
    buf_recv = 0.0

    ! For odd i, send then recv.
    if ( mod(i,2)==1 ) then

        if ( ijk_to_rank(i+1,j,k)/=-1 ) then
            ii = 1
            buf_send(:,:) = phi3d(iu(1),:,:)
#           include "inc_send_recv.f90"
            phi3d(iu(1)+1,:,:) = buf_recv(:,:)
        end if

        if ( ijk_to_rank(i-1,j,k)/=-1 ) then
            ii = -1
            buf_send(:,:) = phi3d(il(1),:,:)
#           include "inc_send_recv.f90"
            phi3d(il(1)-1,:,:) = buf_recv(:,:)
        end if

    ! For even i, recv then send.
    else

        if ( ijk_to_rank(i-1,j,k)/=-1 ) then
            ii = -1
            buf_send(:,:) = phi3d(il(1),:,:)
#           include "inc_recv_send.f90"
            phi3d(il(1)-1,:,:) = buf_recv(:,:)
        end if

        if ( ijk_to_rank(i+1,j,k)/=-1 ) then
            ii = 1
            buf_send(:,:) = phi3d(iu(1),:,:)
#           include "inc_recv_send.f90"
            phi3d(iu(1)+1,:,:) = buf_recv(:,:)
        end if

    end if

    deallocate(buf_send,buf_recv)

end if
