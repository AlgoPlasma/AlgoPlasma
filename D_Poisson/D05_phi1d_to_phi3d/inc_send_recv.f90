call mpi_send(buf_send(:,:),size(buf_send(:,:)),mpi_double,&
    ijk_to_rank(i+ii,j+jj,k+kk),mpi_i,mpi_comm_world,ierr)

call mpi_recv(buf_recv(:,:),size(buf_recv(:,:)),mpi_double,&
    ijk_to_rank(i+ii,j+jj,k+kk),ijk_to_rank(i+ii,j+jj,k+kk),mpi_comm_world,stat,ierr)
