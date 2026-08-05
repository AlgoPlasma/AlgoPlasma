!> @file sub_F02_par_output_h5.f90
!> @brief Write particle data to per-rank HDF5 files.
!>
!> @details
!> Each MPI rank writes its local particle data to an HDF5 ``.h5`` file
!> under directory ``trim(label)``. Rank 0 creates the output directory
!> using ``mkdir -p``, then all ranks synchronize with ``mpi_barrier``
!> before writing files.
!>
!> The output file name has the form
!> ``label/label_time_rank.h5``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``.
!>
!> The routine writes the first ``np`` columns of the 2D particle array
!> ``par`` to a dataset named ``par`` with shape ``(nvar,np)``, where
!> ``nvar = size(par,1)``.
!> The dataset is written from ``par(:,1:np)`` in Fortran array element
!> order (column-major, first index varying fastest).
!>
!> Two scalar integer attributes are attached to the dataset:
!> ``it`` and ``rank``.
!>
!> The dataset datatype is mapped from the Fortran kinds at runtime using
!> ``h5kind_to_type``: ``kind(par(1,1))`` for the particle array and ``kind(0)``
!> for integer attributes. The resulting HDF5 datatype IDs are then used in
!> ``h5dcreate_f/h5dwrite_f`` and ``h5acreate_f/h5awrite_f``.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``e`` or ``ion``.
!> Do not pass a string containing ``/``, since ``label`` is used
!> both as the output directory name and as the file name prefix.
!>
!> @note
!> 1. Requires the MPI module and the HDF5 Fortran module.
!> 2. Assumes ``par`` stores particle properties column-wise.
!> 3. The caller must ensure ``size(par,2) >= np``.
!> 4. The HDF5 datatype is obtained via ``h5kind_to_type``; the real/integer kinds
!> must be supported by the linked HDF5 library (typically 4-byte or 8-byte real,
!> and default integer).
!>
!> @author Zhe LIU (2025/11/04), Yinjian ZHAO (2026/02/28).
!>
!> @param[in] label: character(*), output directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, time step index encoded in the file name and
!>   stored as dataset attribute ``it``.
!> @param[in] np: integer, number of particle columns ``par(:,p)``
!>   written for the local MPI rank.
!> @param[in] par: real,dimension(:,:), particle data array stored
!>   column-wise as ``par(:,p)`` for ``p = 1..np``.

subroutine sub_F02_par_output_h5(label,it,np,par)

    use mpi
    use hdf5

    implicit none

    character(len=*) :: label
    integer :: it,np
    real,dimension(:,:) :: par

    integer :: mpi_i,ierr
    integer :: nvar,ncol_buf
    integer :: hdferr
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename

    integer(hsize_t),dimension(2) :: dims
    integer(hsize_t),dimension(1) :: one

    integer(hid_t) :: file_id,dset_id,space_id
    integer(hid_t) :: aspace_id,attr_id
    integer(hid_t) :: h5_real_type,h5_int_type

    integer :: buf_it(1),buf_rank(1)

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    nvar = size(par,1)
    ncol_buf = size(par,2)

    if (np < 0 .or. np > ncol_buf) then
        write(*,'(A,I0,A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): invalid np=', np, ', size(par,2)=', ncol_buf
        call mpi_abort(mpi_comm_world,1211,ierr)
    end if

    if (nvar < 1) then
        write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): invalid size(par,1)=', nvar
        call mpi_abort(mpi_comm_world,1212,ierr)
    end if

    if (mpi_i == 0) call execute_command_line('mkdir -p ' // trim(label))
    call mpi_barrier(mpi_comm_world,ierr)

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.h5'

    one(1) = 1_hsize_t
    dims = (/int(nvar,hsize_t),int(np,hsize_t)/)

    call h5open_f(hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): h5open_f failed'
        call mpi_abort(mpi_comm_world,1214,ierr)
    end if

    h5_real_type = h5kind_to_type(kind(par(1,1)), H5_REAL_KIND)
    if (h5_real_type < 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, '): h5kind_to_type failed for real'
        call mpi_abort(mpi_comm_world, 1213, ierr)
    end if

    h5_int_type = h5kind_to_type(kind(0), H5_INTEGER_KIND)
    if (h5_int_type < 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, '): h5kind_to_type failed for integer'
        call mpi_abort(mpi_comm_world, 1213, ierr)
    end if

    call h5fcreate_f(trim(filename),H5F_ACC_TRUNC_F,file_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): cannot create file: ', trim(filename)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1215,ierr)
    end if

    call h5screate_simple_f(2,dims,space_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): h5screate_simple_f failed'
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1216,ierr)
    end if

    call h5dcreate_f(file_id,'par',h5_real_type,space_id,dset_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): h5dcreate_f("par") failed'
        call h5sclose_f(space_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1217,ierr)
    end if

    if (np > 0) then
        call h5dwrite_f(dset_id,h5_real_type,par(:,1:np),dims,hdferr)
        if (hdferr /= 0) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): h5dwrite_f failed'
            call h5dclose_f(dset_id,hdferr)
            call h5sclose_f(space_id,hdferr)
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1218,ierr)
        end if
    end if

    call h5screate_simple_f(1,one,aspace_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): h5screate_simple_f for attribute failed'
        call h5dclose_f(dset_id,hdferr)
        call h5sclose_f(space_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1219,ierr)
    end if

    buf_it(1) = it
    call h5acreate_f(dset_id,'it',h5_int_type,aspace_id,attr_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): cannot create attribute "it"'
        call h5sclose_f(aspace_id,hdferr)
        call h5dclose_f(dset_id,hdferr)
        call h5sclose_f(space_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1220,ierr)
    end if

    call h5awrite_f(attr_id,h5_int_type,buf_it,one,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): cannot write attribute "it"'
        call h5aclose_f(attr_id,hdferr)
        call h5sclose_f(aspace_id,hdferr)
        call h5dclose_f(dset_id,hdferr)
        call h5sclose_f(space_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1221,ierr)
    end if
    call h5aclose_f(attr_id,hdferr)

    buf_rank(1) = mpi_i
    call h5acreate_f(dset_id,'rank',h5_int_type,aspace_id,attr_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): cannot create attribute "rank"'
        call h5sclose_f(aspace_id,hdferr)
        call h5dclose_f(dset_id,hdferr)
        call h5sclose_f(space_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1222,ierr)
    end if

    call h5awrite_f(attr_id,h5_int_type,buf_rank,one,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): cannot write attribute "rank"'
        call h5aclose_f(attr_id,hdferr)
        call h5sclose_f(aspace_id,hdferr)
        call h5dclose_f(dset_id,hdferr)
        call h5sclose_f(space_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1223,ierr)
    end if
    call h5aclose_f(attr_id,hdferr)

    call h5sclose_f(aspace_id,hdferr)
    call h5dclose_f(dset_id,hdferr)
    call h5sclose_f(space_id,hdferr)
    call h5fclose_f(file_id,hdferr)
    call h5close_f(hdferr)

end subroutine sub_F02_par_output_h5
