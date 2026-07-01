!> @file sub_F01_par_load_count.f90
!> @brief Get local particle count np from per-rank dat/bin/h5 file.
!>
!> @details
!> File name pattern:
!>   label/label_time_rank.EXT
!> time = it formatted as I10.10, rank = MPI rank formatted as I5.5.
!>
!> Counting method:
!> - tag='dat'  : count non-empty lines.
!> - tag='bin'  : np = filesize_bytes / (nvar * bytes_per_default_real).
!> - tag='h5'   : np = second dimension of dataset "par".
!> - tag='hdf5' : same as 'h5'.
!>
!> @author Yinjian ZHAO (2026/03/03).
!>
!> @param[in]  tag   : 'dat'|'bin'|'h5'|'hdf5'
!> @param[in]  label : directory and file prefix
!> @param[in]  it    : iteration index encoded in file name
!> @param[in]  nvar  : number of particle variables (required for 'bin';
!>                     optional check for 'h5'; ignored for 'dat')
!> @param[out] np    : particle count inferred from file

subroutine sub_F01_load_par_count(tag,label,it,nvar,np)

    use mpi
#if (USE_HDF5==1)
    use hdf5
#endif

    implicit none

    character(len=*) :: tag,label
    integer :: it,nvar,np

    integer :: mpi_i,ierr
    integer :: unit,ios
    character(len=10)   :: time
    character(len=5)    :: rank
    character(len=512)  :: filename
    character(len=2048) :: line
    character(len=256)  :: iomsg

    integer, parameter :: ik8 = selected_int_kind(18)
    integer(kind=ik8) :: fsize, bytes_per_real, bytes_per_par, np8

#if (USE_HDF5==1)
    ! HDF5 handles
    integer :: hdferr, ndims
    integer(hid_t) :: file_id, dset_id, fspace_id
    integer(hsize_t), dimension(2) :: dims_file, maxdims
#endif

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i

    unit = mpi_i + 1000

    select case (adjustl(tag))

    case ('dat')
        filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.dat'

        open(unit,file=trim(filename),status='old',action='read', &
            iostat=ios,iomsg=iomsg)
        if (ios /= 0) then
            write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
                '): cannot open file: ', trim(filename)
            write(*,'(A)') trim(iomsg)
            call mpi_abort(mpi_comm_world,1301,ierr)
        end if

        np = 0
        do
            read(unit,'(A)',iostat=ios,iomsg=iomsg) line
            if (ios < 0) exit              ! EOF
            if (ios > 0) then
                write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
                    '): read failed: ', trim(filename)
                write(*,'(A)') trim(iomsg)
                close(unit)
                call mpi_abort(mpi_comm_world,1302,ierr)
            end if
            if (len_trim(line) == 0) cycle ! skip blank line
            np = np + 1
        end do

        close(unit)

    case ('bin')
        if (nvar <= 0) then
            write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
                '): invalid nvar=', nvar
            call mpi_abort(mpi_comm_world,1311,ierr)
        end if

        filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.bin'

        open(unit,file=trim(filename),status='old',form='unformatted', &
            access='stream',action='read',iostat=ios,iomsg=iomsg)
        if (ios /= 0) then
            write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
                '): cannot open file: ', trim(filename)
            write(*,'(A)') trim(iomsg)
            call mpi_abort(mpi_comm_world,1312,ierr)
        end if

        inquire(unit=unit, size=fsize, iostat=ios, iomsg=iomsg)
        if (ios /= 0) then
            write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
                '): inquire(size) failed for: ', trim(filename)
            write(*,'(A)') trim(iomsg)
            close(unit)
            call mpi_abort(mpi_comm_world,1313,ierr)
        end if

        close(unit)

        bytes_per_real = storage_size(0.0)/8
        bytes_per_par  = int(nvar,kind=ik8) * bytes_per_real

        if (bytes_per_par <= 0_ik8) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): invalid bytes_per_par.'
            call mpi_abort(mpi_comm_world,1314,ierr)
        end if

        if (mod(fsize, bytes_per_par) /= 0_ik8) then
            write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
                '): file size not divisible by nvar*bytes_real: ', trim(filename)
            write(*,'(A,I0,A,I0,A,I0)') '  fsize=', fsize, &
                ', nvar=', nvar, ', bytes_real=', bytes_per_real
            call mpi_abort(mpi_comm_world,1315,ierr)
        end if

        np8 = fsize / bytes_per_par
        if (np8 > int(huge(np),kind=ik8)) then
            write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
                '): np overflow for default integer, np8=', np8
            call mpi_abort(mpi_comm_world,1316,ierr)
        end if
        np = int(np8)

    case ('h5','hdf5')
#if (USE_HDF5==1)
        filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.h5'

        call h5open_f(hdferr)
        if (hdferr /= 0) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): h5open_f failed'
            call mpi_abort(mpi_comm_world,1321,ierr)
        end if

        call h5fopen_f(trim(filename),H5F_ACC_RDONLY_F,file_id,hdferr)
        if (hdferr /= 0) then
            write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
                '): cannot open file: ', trim(filename)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1322,ierr)
        end if

        call h5dopen_f(file_id,'par',dset_id,hdferr)
        if (hdferr /= 0) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): dataset "par" not found'
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1323,ierr)
        end if

        call h5dget_space_f(dset_id,fspace_id,hdferr)
        if (hdferr /= 0) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): h5dget_space_f failed'
            call h5dclose_f(dset_id,hdferr)
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1324,ierr)
        end if

        call h5sget_simple_extent_ndims_f(fspace_id,ndims,hdferr)
        if (hdferr /= 0 .or. ndims /= 2) then
            write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
                '): dataset rank mismatch, ndims=', ndims
            call h5sclose_f(fspace_id,hdferr)
            call h5dclose_f(dset_id,hdferr)
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1325,ierr)
        end if

        call h5sget_simple_extent_dims_f(fspace_id,dims_file,maxdims,hdferr)
        if (hdferr /= 0) then
            write(*,'(A,I0,A)') 'ERROR(rank=', mpi_i, &
                '): h5sget_simple_extent_dims_f failed'
            call h5sclose_f(fspace_id,hdferr)
            call h5dclose_f(dset_id,hdferr)
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1326,ierr)
        end if

        if (nvar > 0) then
            if (dims_file(1) < int(nvar,hsize_t)) then
                write(*,'(A,I0,A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
                    '): not enough rows in dataset, need ', nvar, &
                    ', file has ', int(dims_file(1))
                call h5sclose_f(fspace_id,hdferr)
                call h5dclose_f(dset_id,hdferr)
                call h5fclose_f(file_id,hdferr)
                call h5close_f(hdferr)
                call mpi_abort(mpi_comm_world,1327,ierr)
            end if
        end if

        if (dims_file(2) > int(huge(np),kind=hsize_t)) then
            write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
                '): np overflow for default integer, ncol_file=', &
                int(dims_file(2))
            call h5sclose_f(fspace_id,hdferr)
            call h5dclose_f(dset_id,hdferr)
            call h5fclose_f(file_id,hdferr)
            call h5close_f(hdferr)
            call mpi_abort(mpi_comm_world,1328,ierr)
        end if

        np = int(dims_file(2))

        call h5sclose_f(fspace_id,hdferr)
        call h5dclose_f(dset_id,hdferr)
        call h5fclose_f(file_id,hdferr)
        call h5close_f(hdferr)
#else
        if (mpi_i == 0) then
            write(*,'(A)') 'ERROR: HDF5 is disabled (rebuild with -DUSE_HDF5=1).'
        end if
        call mpi_abort(mpi_comm_world,1320,ierr)
#endif

    case default
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): unsupported tag=', trim(tag)
        call mpi_abort(mpi_comm_world,1399,ierr)

    end select

end subroutine sub_F01_load_par_count
