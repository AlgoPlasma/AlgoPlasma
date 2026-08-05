!> @file sub_F01_par_load_h5.f90
!> @brief Load particle data from per-rank HDF5 files.
!>
!> @details
!> Each MPI rank reads its local particle data from an HDF5 ``.h5`` file
!> under directory ``trim(label)``.
!>
!> The input file name has the form
!> ``label/label_time_rank.h5``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``.
!>
!> The file format must match that written by ``sub_F02_par_output_h5``.
!> The file is expected to contain a dataset named ``par`` with rank 2 and
!> shape ``(nvar_file,ncol_file)`` in Fortran storage order, where each
!> column stores one particle and each row stores one particle property.
!> This routine reads the first ``np`` columns into ``par(:,1:np)`` using a
!> hyperslab selection.
!>
!> The memory datatype passed to ``h5dread_f`` is obtained via
!> ``h5kind_to_type(kind(par(1,1)), H5_REAL_KIND)``, so it matches the
!> Fortran ``real`` kind used by ``par`` at runtime.
!>
!> The dataset attributes such as ``it`` and ``rank`` may exist in the file,
!> but they are not used by this routine.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``e`` or ``ion``. Do not pass a string containing
!> ``/``, since ``label`` is used both as the input directory name and as the
!> file name prefix.
!>
!> @note
!> 1. Requires the MPI module and the HDF5 Fortran module.
!> 2. The caller must ensure ``size(par,2) >= np``.
!> 3. The dataset ``par`` must be rank 2. If the dataset is smaller than
!>    ``(size(par,1),np)``, the hyperslab selection or ``h5dread_f`` will fail.
!> 4. The HDF5 datatype is mapped from the Fortran ``real`` kind of ``par``
!>    using ``h5kind_to_type``; the kind must be supported by the linked HDF5
!>    library (typically 4-byte or 8-byte real).
!>
!> @author Zhe LIU (2025/11/04), Yinjian ZHAO (2026/02/28).
!>
!> @param[in]  label Input directory and file name prefix; must not contain ``/``.
!> @param[in]  it    Current time step or iteration index encoded in the file name.
!> @param[in]  np    Number of particle columns to read from dataset ``par``.
!> @param[out] par   2D buffer that receives ``par(:,1:np)``.

subroutine sub_F01_par_load_h5(label,it,np,par)

    use mpi
    use hdf5

    implicit none

    character(len=*) :: label
    integer :: it,np
    real,dimension(:,:) :: par

    integer :: mpi_i,ierr
    integer :: nvar,ncol_buf
    integer :: hdferr,ndims
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename

    integer(hid_t) :: file_id,dset_id,fspace_id,mspace_id
    integer(hid_t) :: h5_real_type
    integer(hsize_t),dimension(2) :: count
    integer(hsize_t),dimension(2) :: start

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    nvar = size(par,1)
    ncol_buf = size(par,2)

    if (nvar < 1) then
        write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): invalid size(par,1)=', nvar
        call mpi_abort(mpi_comm_world,1111,ierr)
    end if

    if (np < 0 .or. np > ncol_buf) then
        write(*,'(A,I0,A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): invalid np=', np, ', size(par,2)=', ncol_buf
        call mpi_abort(mpi_comm_world,1112,ierr)
    end if

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.h5'

    call h5open_f(hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): h5open_f failed'
        call mpi_abort(mpi_comm_world,1114,ierr)
    end if

    h5_real_type = h5kind_to_type(kind(par(1,1)), H5_REAL_KIND)
    if (h5_real_type < 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, '): h5kind_to_type failed'
        call mpi_abort(mpi_comm_world, 1213, ierr)
    end if

    call h5fopen_f(trim(filename),H5F_ACC_RDONLY_F,file_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): cannot open file: ', trim(filename)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1115,ierr)
    end if

    call h5dopen_f(file_id,'par',dset_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): dataset "par" not found'
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1116,ierr)
    end if

    call h5dget_space_f(dset_id,fspace_id,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): h5dget_space_f failed'
        call h5dclose_f(dset_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1117,ierr)
    end if

    call h5sget_simple_extent_ndims_f(fspace_id,ndims,hdferr)
    if (hdferr /= 0) then
        write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
            '): h5sget_simple_extent_ndims_f failed'
        call h5sclose_f(fspace_id,hdferr)
        call h5dclose_f(dset_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1118,ierr)
    end if

    if (ndims /= 2) then
        write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): dataset rank mismatch, ndims=', ndims
        call h5sclose_f(fspace_id,hdferr)
        call h5dclose_f(dset_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
        call mpi_abort(mpi_comm_world,1119,ierr)
    end if

    if (np > 0) then

        start = (/0_hsize_t,0_hsize_t/)
        count = (/int(nvar,hsize_t),int(np,hsize_t)/)

        call h5sselect_hyperslab_f(fspace_id,H5S_SELECT_SET_F,start,count,hdferr)
        if (hdferr /= 0) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): h5sselect_hyperslab_f failed'
            call h5sclose_f(fspace_id,hdferr)
            call h5dclose_f(dset_id,hdferr)
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1123,ierr)
        end if

        call h5screate_simple_f(2,count,mspace_id,hdferr)
        if (hdferr /= 0) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): h5screate_simple_f for memory space failed'
            call h5sclose_f(fspace_id,hdferr)
            call h5dclose_f(dset_id,hdferr)
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1124,ierr)
        end if

        call h5dread_f(dset_id,h5_real_type,par(:,1:np),count,hdferr, &
            mspace_id,fspace_id)
        if (hdferr /= 0) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): h5dread_f failed'
            call h5sclose_f(mspace_id,hdferr)
            call h5sclose_f(fspace_id,hdferr)
            call h5dclose_f(dset_id,hdferr)
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1125,ierr)
        end if

        call h5sclose_f(mspace_id,hdferr)

    end if

    call h5sclose_f(fspace_id,hdferr)
    call h5dclose_f(dset_id,hdferr)
    call h5fclose_f(file_id,hdferr)
    call h5close_f(hdferr)

end subroutine sub_F01_par_load_h5
