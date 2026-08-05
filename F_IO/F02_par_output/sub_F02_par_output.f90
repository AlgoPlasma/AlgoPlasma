!> @file sub_F02_par_output.f90
!> @brief Dispatch particle output to a format-specific writer.
!>
!> @details
!> This routine selects a low-level particle output subroutine according
!> to the format tag ``tag``.
!>
!> Supported tags are:
!> - ``dat``  : ASCII text output
!> - ``bin``  : raw binary stream output
!> - ``h5``   : HDF5 output
!> - ``hdf5`` : HDF5 output
!>
!> If the tag is not recognized, the routine prints an error message and
!> falls back to the ASCII ``dat`` writer.
!>
!> @author Zhe LIU (2025/11/04), Yinjian ZHAO (2026/02/28).
!>
!> @param[in] tag: character(*), format selector string.
!> @param[in] label: character(*), output directory and file name prefix
!>   forwarded to the chosen output routine.
!> @param[in] it: integer, time step or iteration index passed through to
!>   the chosen output routine.
!> @param[in] np: integer, number of particles stored in columns of
!>   ``par`` to be written.
!> @param[in] par: real,dimension(:,:), particle phase-space array of the
!>   local MPI rank, stored column-wise as ``par(:,p)``.

subroutine sub_F02_par_output(tag,label,it,np,par)

    implicit none

    character(len=*) :: tag,label
    integer :: it,np
    real,dimension(:,:) :: par

    select case (trim(adjustl(tag)))
    case ('dat')
        call sub_F02_par_output_dat(label,it,np,par)

    case ('bin')
        call sub_F02_par_output_bin(label,it,np,par)

#if (USE_HDF5==1)
    case ('h5','hdf5')
        call sub_F02_par_output_h5(label,it,np,par)
#endif

    case default
        write(*,'(A,A,A)') 'ERROR: unknown particle output tag = "', &
            trim(tag), '", switch to "dat".'
        call sub_F02_par_output_dat(label,it,np,par)
    end select

end subroutine sub_F02_par_output
