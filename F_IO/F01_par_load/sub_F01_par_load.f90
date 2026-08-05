!> @file sub_F01_par_load.f90
!> @brief Dispatch particle loading to a format-specific reader.
!>
!> @details
!> This routine selects a low-level particle load subroutine according to
!> the format tag ``tag``.
!>
!> Supported tags are:
!> - ``dat``  : ASCII text input
!> - ``bin``  : raw binary stream input
!> - ``h5``   : HDF5 input
!> - ``hdf5`` : HDF5 input
!>
!> If the tag is not recognized, the routine prints an error message and
!> falls back to the ASCII ``dat`` reader.
!>
!> The particle phase-space array ``par`` is always filled on the local
!> MPI rank, and the caller is responsible for ensuring that its shape is
!> compatible with the selected file format and the requested ``np``.
!>
!> @author Zhe LIU (2025/12/03), Yinjian ZHAO (2026/02/28).
!>
!> @param[in] tag: character(*), format selector string.
!> @param[in] label: character(*), input directory and file name prefix
!>   forwarded to the chosen load routine.
!> @param[in] it: integer, time step or iteration index forwarded to the
!>   chosen load routine.
!> @param[in] np: integer, number of particles or records to be loaded on
!>   this MPI rank.
!> @param[out] par: real,dimension(:,:), particle phase-space array of the
!>   local MPI rank that receives loaded data.

subroutine sub_F01_par_load(tag,label,it,np,par)

    implicit none

    character(len=*) :: tag,label
    integer :: it,np
    real,dimension(:,:) :: par

    select case (trim(adjustl(tag)))
    case ('dat')
        call sub_F01_par_load_dat(label,it,np,par)

    case ('bin')
        call sub_F01_par_load_bin(label,it,np,par)

#if (USE_HDF5==1)
    case ('h5','hdf5')
        call sub_F01_par_load_h5(label,it,np,par)
#endif

    case default
        write(*,'(A,A,A)') 'ERROR: unknown particle load tag = "', &
            trim(tag), '", switch to "dat".'
        call sub_F01_par_load_dat(label,it,np,par)
    end select

end subroutine sub_F01_par_load
