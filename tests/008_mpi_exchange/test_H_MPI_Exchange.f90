program test_H_MPI_Exchange

    use mpi
    use mod_H01_mpi_exchange_field
    use mod_H02_mpi_exchange_par
    use mod_H03_mpi_exchange_den

    implicit none

    integer :: ierr, mpi_i, mpi_n
    integer :: failures_local, failures_global

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, mpi_i, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, mpi_n, ierr)

    if (mpi_n /= 4) then
        if (mpi_i == 0) then
            write(*,*) "ERROR: test_H_MPI_Exchange requires exactly 4 MPI ranks."
            write(*,*) "Run with: mpiexec -n 4 ./build/test_H_MPI_Exchange.exe"
        end if
        call MPI_Finalize(ierr)
        stop 1
    end if

    failures_local = 0

    call test_H01_field_exchange(failures_local)
    call test_H03_density_exchange(failures_local)
    call test_H02_particle_exchange(failures_local)

    call MPI_Allreduce(failures_local, failures_global, 1, MPI_INTEGER, &
        MPI_SUM, MPI_COMM_WORLD, ierr)

    if (mpi_i == 0) then
        if (failures_global == 0) then
            write(*,*) "PASS: H_MPI_Exchange small MPI regression suite."
        else
            write(*,*) "FAIL: H_MPI_Exchange failures =", failures_global
        end if
    end if

    call MPI_Finalize(ierr)

    if (failures_global == 0) then
        stop 0
    else
        stop 1
    end if

contains

    subroutine test_H01_field_exchange(failures)

        integer, intent(inout) :: failures
        integer :: il(3), iu(3), domain_split(3)
        integer :: rank_to_ijk(3,0:3)
        integer :: ijk_to_rank(0:3,0:3,0:2)
        real :: l(3)
        real, allocatable :: f(:,:,:)
        integer :: i0, j0, k0, nbr, ii, jj, kk, r
        real :: expected

        domain_split = (/2, 2, 1/)
        call init_topology(4, domain_split, rank_to_ijk, ijk_to_rank)

        i0 = rank_to_ijk(1, mpi_i)
        j0 = rank_to_ijk(2, mpi_i)
        k0 = rank_to_ijk(3, mpi_i)

        il = (/1, 1, 1/)
        iu = (/4, 4, 3/)
        l = (/0.0, 0.0, 0.0/)

        allocate(f(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        do kk = il(3)-1, iu(3)+1
            do jj = il(2)-1, iu(2)+1
                do ii = il(1)-1, iu(1)+1
                    f(ii,jj,kk) = field_value(mpi_i, ii, jj, kk)
                end do
            end do
        end do

        call sub_H01_mpi_exchange_field(il, iu, f, 4, rank_to_ijk, &
            domain_split, ijk_to_rank, l)

        if (i0 < domain_split(1)) then
            nbr = ijk_to_rank(i0+1,j0,k0)
            do kk = 1, iu(3)
                do jj = 1, iu(2)
                    expected = field_value(nbr, il(1)+1, jj, kk)
                    call check_close("H01 x_plus halo", f(iu(1)+1,jj,kk), &
                        expected, failures)
                end do
            end do
        end if

        if (i0 > 1) then
            nbr = ijk_to_rank(i0-1,j0,k0)
            do kk = 1, iu(3)
                do jj = 1, iu(2)
                    expected = field_value(nbr, iu(1)-1, jj, kk)
                    call check_close("H01 x_minus halo", f(il(1)-1,jj,kk), &
                        expected, failures)
                end do
            end do
        end if

        if (j0 < domain_split(2)) then
            nbr = ijk_to_rank(i0,j0+1,k0)
            do kk = 1, iu(3)
                do ii = 1, iu(1)
                    expected = field_value(nbr, ii, il(2)+1, kk)
                    call check_close("H01 y_plus halo", f(ii,iu(2)+1,kk), &
                        expected, failures)
                end do
            end do
        end if

        if (j0 > 1) then
            nbr = ijk_to_rank(i0,j0-1,k0)
            do kk = 1, iu(3)
                do ii = 1, iu(1)
                    expected = field_value(nbr, ii, iu(2)-1, kk)
                    call check_close("H01 y_minus halo", f(ii,il(2)-1,kk), &
                        expected, failures)
                end do
            end do
        end if

        deallocate(f)

        l = (/0.0, 0.0, 3.0/)
        allocate(f(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        do kk = il(3)-1, iu(3)+1
            do jj = il(2)-1, iu(2)+1
                do ii = il(1)-1, iu(1)+1
                    f(ii,jj,kk) = field_value(mpi_i, ii, jj, kk)
                end do
            end do
        end do

        call sub_H01_mpi_exchange_field(il, iu, f, 4, rank_to_ijk, &
            domain_split, ijk_to_rank, l)

        expected = field_value(mpi_i, 2, 2, iu(3)-1)
        call check_close("H01 z periodic lower ghost", f(2,2,il(3)-1), &
            expected, failures)
        expected = field_value(mpi_i, 2, 2, il(3)+1)
        call check_close("H01 z periodic upper ghost", f(2,2,iu(3)+1), &
            expected, failures)

        if (mpi_i == 0) then
            open(unit=40, file="build/h01_field_faces.dat", status="replace", &
                action="write")
            write(40,'(a)') "rank case sample_i sample_j sample_k actual expected abs_error"
            close(40)
        end if
        call MPI_Barrier(MPI_COMM_WORLD, ierr)

        do r = 0, 3
            if (mpi_i == r) then
                open(unit=40, file="build/h01_field_faces.dat", status="old", &
                    position="append", action="write")
                if (i0 < domain_split(1)) then
                    nbr = ijk_to_rank(i0+1,j0,k0)
                    expected = field_value(nbr, il(1)+1, 2, 2)
                    call write_plot_row(40, "x_plus", mpi_i, iu(1)+1, 2, 2, &
                        f(iu(1)+1,2,2), expected)
                end if
                if (i0 > 1) then
                    nbr = ijk_to_rank(i0-1,j0,k0)
                    expected = field_value(nbr, iu(1)-1, 2, 2)
                    call write_plot_row(40, "x_minus", mpi_i, il(1)-1, 2, 2, &
                        f(il(1)-1,2,2), expected)
                end if
                if (j0 < domain_split(2)) then
                    nbr = ijk_to_rank(i0,j0+1,k0)
                    expected = field_value(nbr, 2, il(2)+1, 2)
                    call write_plot_row(40, "y_plus", mpi_i, 2, iu(2)+1, 2, &
                        f(2,iu(2)+1,2), expected)
                end if
                if (j0 > 1) then
                    nbr = ijk_to_rank(i0,j0-1,k0)
                    expected = field_value(nbr, 2, iu(2)-1, 2)
                    call write_plot_row(40, "y_minus", mpi_i, 2, il(2)-1, 2, &
                        f(2,il(2)-1,2), expected)
                end if
                expected = field_value(mpi_i, 2, 2, iu(3)-1)
                call write_plot_row(40, "z_periodic_low", mpi_i, 2, 2, &
                    il(3)-1, f(2,2,il(3)-1), expected)
                expected = field_value(mpi_i, 2, 2, il(3)+1)
                call write_plot_row(40, "z_periodic_high", mpi_i, 2, 2, &
                    iu(3)+1, f(2,2,iu(3)+1), expected)
                close(40)
            end if
            call MPI_Barrier(MPI_COMM_WORLD, ierr)
        end do

        deallocate(f)

    end subroutine test_H01_field_exchange

    subroutine test_H03_density_exchange(failures)

        integer, intent(inout) :: failures
        integer :: il(3), iu(3), domain_split(3)
        integer :: rank_to_ijk(3,0:3)
        integer :: ijk_to_rank(0:3,0:3,0:2)
        real :: l(3)
        real, allocatable :: den(:,:,:)
        integer :: i0, j0, k0, nbr, ii, jj, kk, r
        real :: expected

        domain_split = (/2, 2, 1/)
        call init_topology(4, domain_split, rank_to_ijk, ijk_to_rank)

        i0 = rank_to_ijk(1, mpi_i)
        j0 = rank_to_ijk(2, mpi_i)
        k0 = rank_to_ijk(3, mpi_i)

        il = (/1, 1, 1/)
        iu = (/3, 3, 2/)
        l = (/0.0, 0.0, 0.0/)

        allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        call fill_density(den, il, iu)

        call sub_H03_mpi_exchange_den(il, iu, den, 4, rank_to_ijk, &
            domain_split, ijk_to_rank, l)

        if (i0 < domain_split(1)) then
            nbr = ijk_to_rank(i0+1,j0,k0)
            do kk = 1, iu(3)
                expected = density_value(mpi_i, iu(1), 2, kk) + &
                    density_value(nbr, il(1), 2, kk)
                call check_close("H03 x_plus boundary accumulation", &
                    den(iu(1),2,kk), expected, failures)
            end do
        end if

        if (i0 > 1) then
            nbr = ijk_to_rank(i0-1,j0,k0)
            do kk = 1, iu(3)
                expected = density_value(mpi_i, il(1), 2, kk) + &
                    density_value(nbr, iu(1), 2, kk)
                call check_close("H03 x_minus boundary accumulation", &
                    den(il(1),2,kk), expected, failures)
            end do
        end if

        if (j0 < domain_split(2)) then
            nbr = ijk_to_rank(i0,j0+1,k0)
            do kk = 1, iu(3)
                expected = density_value(mpi_i, 2, iu(2), kk) + &
                    density_value(nbr, 2, il(2), kk)
                call check_close("H03 y_plus boundary accumulation", &
                    den(2,iu(2),kk), expected, failures)
            end do
        end if

        if (j0 > 1) then
            nbr = ijk_to_rank(i0,j0-1,k0)
            do kk = 1, iu(3)
                expected = density_value(mpi_i, 2, il(2), kk) + &
                    density_value(nbr, 2, iu(2), kk)
                call check_close("H03 y_minus boundary accumulation", &
                    den(2,il(2),kk), expected, failures)
            end do
        end if

        deallocate(den)

        l = (/0.0, 0.0, 2.0/)
        allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        call fill_density(den, il, iu)

        call sub_H03_mpi_exchange_den(il, iu, den, 4, rank_to_ijk, &
            domain_split, ijk_to_rank, l)

        expected = density_value(mpi_i, 2, 2, il(3)) + &
            density_value(mpi_i, 2, 2, iu(3))
        call check_close("H03 z periodic lower fold", den(2,2,il(3)), &
            expected, failures)
        call check_close("H03 z periodic upper fold", den(2,2,iu(3)), &
            expected, failures)

        if (mpi_i == 0) then
            open(unit=41, file="build/h03_density_faces.dat", status="replace", &
                action="write")
            write(41,'(a)') "rank case sample_i sample_j sample_k actual expected abs_error"
            close(41)
        end if
        call MPI_Barrier(MPI_COMM_WORLD, ierr)

        do r = 0, 3
            if (mpi_i == r) then
                open(unit=41, file="build/h03_density_faces.dat", status="old", &
                    position="append", action="write")
                if (i0 < domain_split(1)) then
                    nbr = ijk_to_rank(i0+1,j0,k0)
                    expected = density_value(mpi_i, iu(1), 2, 1) + &
                        density_value(mpi_i, iu(1), 2, 2) + &
                        density_value(nbr, il(1), 2, 1) + &
                        density_value(nbr, il(1), 2, 2)
                    call write_plot_row(41, "x_plus", mpi_i, iu(1), 2, 1, &
                        den(iu(1),2,1), expected)
                end if
                if (i0 > 1) then
                    nbr = ijk_to_rank(i0-1,j0,k0)
                    expected = density_value(mpi_i, il(1), 2, 1) + &
                        density_value(mpi_i, il(1), 2, 2) + &
                        density_value(nbr, iu(1), 2, 1) + &
                        density_value(nbr, iu(1), 2, 2)
                    call write_plot_row(41, "x_minus", mpi_i, il(1), 2, 1, &
                        den(il(1),2,1), expected)
                end if
                if (j0 < domain_split(2)) then
                    nbr = ijk_to_rank(i0,j0+1,k0)
                    expected = density_value(mpi_i, 2, iu(2), 1) + &
                        density_value(mpi_i, 2, iu(2), 2) + &
                        density_value(nbr, 2, il(2), 1) + &
                        density_value(nbr, 2, il(2), 2)
                    call write_plot_row(41, "y_plus", mpi_i, 2, iu(2), 1, &
                        den(2,iu(2),1), expected)
                end if
                if (j0 > 1) then
                    nbr = ijk_to_rank(i0,j0-1,k0)
                    expected = density_value(mpi_i, 2, il(2), 1) + &
                        density_value(mpi_i, 2, il(2), 2) + &
                        density_value(nbr, 2, iu(2), 1) + &
                        density_value(nbr, 2, iu(2), 2)
                    call write_plot_row(41, "y_minus", mpi_i, 2, il(2), 1, &
                        den(2,il(2),1), expected)
                end if
                expected = density_value(mpi_i, 2, 2, il(3)) + &
                    density_value(mpi_i, 2, 2, iu(3))
                call write_plot_row(41, "z_periodic", mpi_i, 2, 2, il(3), &
                    den(2,2,il(3)), expected)
                close(41)
            end if
            call MPI_Barrier(MPI_COMM_WORLD, ierr)
        end do

        deallocate(den)

    end subroutine test_H03_density_exchange

    subroutine test_H02_particle_exchange(failures)

        integer, intent(inout) :: failures
        integer, parameter :: ns = 2, npmax = 16, npm = 8
        integer :: domain_split(3)
        integer :: rank_to_ijk(3,0:3)
        integer :: ijk_to_rank(0:3,0:3,0:2)
        integer :: np(ns), il(3), iu(3), il0(3), iu0(3)
        real :: par(1:6,1:npmax,1:ns)
        real :: l(3), xlo, xhi, ylo, yhi
        integer :: i0, j0, k0, nsmax, istat, s, p, r
        integer :: exp1(5), exp2(2)

        domain_split = (/2, 2, 1/)
        call init_topology(4, domain_split, rank_to_ijk, ijk_to_rank)

        i0 = rank_to_ijk(1, mpi_i)
        j0 = rank_to_ijk(2, mpi_i)
        k0 = rank_to_ijk(3, mpi_i)

        il = (/(i0-1)*4 + 1, (j0-1)*4 + 1, 1/)
        iu = (/ i0*4,       j0*4,       4/)
        il0 = (/1, 1, 1/)
        iu0 = (/8, 8, 4/)
        l = (/0.0, 0.0, 4.0/)

        xlo = real(il(1)-1)
        xhi = real(iu(1))
        ylo = real(il(2)-1)
        yhi = real(iu(2))

        np = 0
        par = 0.0

        call sub_H02_mpi_exchange_par_init(ns, npm, 4, rank_to_ijk, &
            domain_split, ijk_to_rank)

        call add_particle(ns, np, npmax, par, 1, xlo+1.0, ylo+1.1, 1.2, &
            1000 + mpi_i)
        call add_particle(ns, np, npmax, par, 1, xlo+1.2, ylo+1.3, &
            real(iu(3)) + 0.25, 1300 + mpi_i)
        call add_particle(ns, np, npmax, par, 2, xlo+1.4, ylo+1.5, 1.4, &
            2000 + mpi_i)

        select case (mpi_i)
        case (0)
            call add_particle(ns, np, npmax, par, 1, xhi+0.25, ylo+1.5, 1.0, 1201)
            call add_particle(ns, np, npmax, par, 1, xlo+1.5, yhi+0.25, 1.0, 1202)
            call add_particle(ns, np, npmax, par, 1, xhi+0.25, yhi+0.25, 1.0, 1203)
            call add_particle(ns, np, npmax, par, 1, xlo-0.25, ylo+1.5, 1.0, 1900)
            call add_particle(ns, np, npmax, par, 2, xhi+0.20, ylo+1.6, 1.0, 2201)
        case (1)
            call add_particle(ns, np, npmax, par, 1, xlo-0.25, ylo+1.5, 1.0, 1211)
            call add_particle(ns, np, npmax, par, 1, xlo+1.5, yhi+0.25, 1.0, 1212)
            call add_particle(ns, np, npmax, par, 1, xlo-0.25, yhi+0.25, 1.0, 1213)
            call add_particle(ns, np, npmax, par, 2, xlo-0.20, ylo+1.6, 1.0, 2211)
        case (2)
            call add_particle(ns, np, npmax, par, 1, xlo+1.5, ylo-0.25, 1.0, 1221)
            call add_particle(ns, np, npmax, par, 1, xhi+0.25, ylo+1.5, 1.0, 1222)
            call add_particle(ns, np, npmax, par, 1, xhi+0.25, ylo-0.25, 1.0, 1223)
            call add_particle(ns, np, npmax, par, 2, xhi+0.20, ylo+1.6, 1.0, 2222)
        case (3)
            call add_particle(ns, np, npmax, par, 1, xlo-0.25, ylo+1.5, 1.0, 1231)
            call add_particle(ns, np, npmax, par, 1, xlo+1.5, ylo-0.25, 1.0, 1232)
            call add_particle(ns, np, npmax, par, 1, xlo-0.25, ylo-0.25, 1.0, 1233)
            call add_particle(ns, np, npmax, par, 1, xlo+1.5, yhi+0.25, 1.0, 1903)
            call add_particle(ns, np, npmax, par, 2, xlo-0.20, ylo+1.6, 1.0, 2231)
        end select

        call sub_H02_mpi_exchange_par(ns, np, npmax, par, il, iu, il0, iu0, &
            domain_split, l, nsmax, istat)

        call check_int("H02 istat", istat, 0, failures)
        if (nsmax > npm) then
            failures = failures + 1
            write(*,*) "rank", mpi_i, "FAIL H02 nsmax > npm", nsmax, npm
        end if

        select case (mpi_i)
        case (0)
            exp1 = (/1000, 1211, 1221, 1233, 1300/)
            exp2 = (/2000, 2211/)
        case (1)
            exp1 = (/1001, 1201, 1223, 1232, 1301/)
            exp2 = (/2001, 2201/)
        case (2)
            exp1 = (/1002, 1202, 1213, 1231, 1302/)
            exp2 = (/2002, 2231/)
        case default
            exp1 = (/1003, 1203, 1212, 1222, 1303/)
            exp2 = (/2003, 2222/)
        end select

        call check_int("H02 species 1 count", np(1), 5, failures)
        call check_int("H02 species 2 count", np(2), 2, failures)

        do p = 1, size(exp1)
            call expect_local_id(1, exp1(p), ns, np, npmax, par, failures)
        end do
        do p = 1, size(exp2)
            call expect_local_id(2, exp2(p), ns, np, npmax, par, failures)
        end do

        call check_particle_z(1, 1300 + mpi_i, 0.25, ns, np, npmax, par, failures)

        call expect_global_id_count(1900, 0, ns, np, npmax, par, failures)
        call expect_global_id_count(1903, 0, ns, np, npmax, par, failures)

        if (mpi_i == 0) then
            open(unit=42, file="build/h02_particle_exchange.dat", status="replace", &
                action="write")
            write(42,'(a)') "rank species slot id x y z"
            close(42)
        end if
        call MPI_Barrier(MPI_COMM_WORLD, ierr)

        do r = 0, 3
            if (mpi_i == r) then
                open(unit=42, file="build/h02_particle_exchange.dat", status="old", &
                    position="append", action="write")
                do s = 1, ns
                    do p = 1, np(s)
                        write(42,'(i0,1x,i0,1x,i0,1x,i0,3(1x,es20.12))') &
                            mpi_i, s, p, nint(par(4,p,s)), &
                            par(1,p,s), par(2,p,s), par(3,p,s)
                    end do
                end do
                close(42)
            end if
            call MPI_Barrier(MPI_COMM_WORLD, ierr)
        end do

    end subroutine test_H02_particle_exchange

    subroutine init_topology(mpi_n_arg, domain_split, rank_to_ijk, ijk_to_rank)

        integer, intent(in) :: mpi_n_arg
        integer, intent(in) :: domain_split(3)
        integer, intent(out) :: rank_to_ijk(3,0:mpi_n_arg-1)
        integer, intent(out) :: ijk_to_rank(0:domain_split(1)+1, &
            0:domain_split(2)+1, 0:domain_split(3)+1)
        integer :: ii, jj, kk, r

        rank_to_ijk = -1
        ijk_to_rank = -1

        do kk = 1, domain_split(3)
            do jj = 1, domain_split(2)
                do ii = 1, domain_split(1)
                    r = (ii-1) + domain_split(1)*(jj-1) + &
                        domain_split(1)*domain_split(2)*(kk-1)
                    rank_to_ijk(:,r) = (/ii, jj, kk/)
                    ijk_to_rank(ii,jj,kk) = r
                end do
            end do
        end do

    end subroutine init_topology

    subroutine fill_density(den, il, iu)

        integer, intent(in) :: il(3), iu(3)
        real, intent(out) :: den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, &
            il(3)-1:iu(3)+1)
        integer :: ii, jj, kk

        do kk = il(3)-1, iu(3)+1
            do jj = il(2)-1, iu(2)+1
                do ii = il(1)-1, iu(1)+1
                    den(ii,jj,kk) = density_value(mpi_i, ii, jj, kk)
                end do
            end do
        end do

    end subroutine fill_density

    real function field_value(rank, ii, jj, kk)

        integer, intent(in) :: rank, ii, jj, kk

        field_value = 1000.0*real(rank) + 100.0*real(ii) + &
            10.0*real(jj) + real(kk)

    end function field_value

    real function density_value(rank, ii, jj, kk)

        integer, intent(in) :: rank, ii, jj, kk

        density_value = 2000.0*real(rank) + 100.0*real(ii) + &
            10.0*real(jj) + real(kk)

    end function density_value

    subroutine check_close(label, actual, expected, failures)

        character(len=*), intent(in) :: label
        real, intent(in) :: actual, expected
        integer, intent(inout) :: failures
        real :: err

        err = abs(actual - expected)
        if (err > 1.0e-10) then
            failures = failures + 1
            write(*,'(a,i0,a,a,a,es16.8,a,es16.8,a,es16.8)') &
                "rank ", mpi_i, " FAIL ", trim(label), " actual=", actual, &
                " expected=", expected, " err=", err
        end if

    end subroutine check_close

    subroutine check_int(label, actual, expected, failures)

        character(len=*), intent(in) :: label
        integer, intent(in) :: actual, expected
        integer, intent(inout) :: failures

        if (actual /= expected) then
            failures = failures + 1
            write(*,'(a,i0,a,a,a,i0,a,i0)') "rank ", mpi_i, " FAIL ", &
                trim(label), " actual=", actual, " expected=", expected
        end if

    end subroutine check_int

    subroutine write_plot_row(unit_no, case_name, rank, ii, jj, kk, actual, expected)

        integer, intent(in) :: unit_no, rank, ii, jj, kk
        character(len=*), intent(in) :: case_name
        real, intent(in) :: actual, expected

        write(unit_no,'(i0,1x,a,1x,i0,1x,i0,1x,i0,3(1x,es20.12))') &
            rank, trim(case_name), ii, jj, kk, actual, expected, &
            abs(actual - expected)

    end subroutine write_plot_row

    subroutine add_particle(ns, np, npmax, par, species, x, y, z, id)

        integer, intent(in) :: ns, npmax, species, id
        integer, intent(inout) :: np(ns)
        real, intent(inout) :: par(1:6,1:npmax,1:ns)
        real, intent(in) :: x, y, z
        integer :: p

        np(species) = np(species) + 1
        p = np(species)
        par(:,p,species) = 0.0
        par(1,p,species) = x
        par(2,p,species) = y
        par(3,p,species) = z
        par(4,p,species) = real(id)
        par(5,p,species) = real(mpi_i)
        par(6,p,species) = real(species)

    end subroutine add_particle

    logical function has_local_id(species, id, ns, np, npmax, par)

        integer, intent(in) :: species, id, ns, npmax
        integer, intent(in) :: np(ns)
        real, intent(in) :: par(1:6,1:npmax,1:ns)
        integer :: p

        has_local_id = .false.
        do p = 1, np(species)
            if (nint(par(4,p,species)) == id) then
                has_local_id = .true.
                return
            end if
        end do

    end function has_local_id

    subroutine expect_local_id(species, id, ns, np, npmax, par, failures)

        integer, intent(in) :: species, id, ns, npmax
        integer, intent(in) :: np(ns)
        real, intent(in) :: par(1:6,1:npmax,1:ns)
        integer, intent(inout) :: failures

        if (.not. has_local_id(species, id, ns, np, npmax, par)) then
            failures = failures + 1
            write(*,'(a,i0,a,i0,a,i0)') "rank ", mpi_i, &
                " FAIL missing H02 id=", id, " species=", species
        end if

    end subroutine expect_local_id

    subroutine check_particle_z(species, id, expected_z, ns, np, npmax, par, failures)

        integer, intent(in) :: species, id, ns, npmax
        integer, intent(in) :: np(ns)
        real, intent(in) :: par(1:6,1:npmax,1:ns)
        real, intent(in) :: expected_z
        integer, intent(inout) :: failures
        integer :: p
        logical :: found

        found = .false.
        do p = 1, np(species)
            if (nint(par(4,p,species)) == id) then
                found = .true.
                call check_close("H02 local periodic z wrap", par(3,p,species), &
                    expected_z, failures)
            end if
        end do
        if (.not. found) then
            failures = failures + 1
            write(*,'(a,i0,a,i0)') "rank ", mpi_i, &
                " FAIL missing H02 periodic id=", id
        end if

    end subroutine check_particle_z

    subroutine expect_global_id_count(id, expected_count, ns, np, npmax, par, failures)

        integer, intent(in) :: id, expected_count, ns, npmax
        integer, intent(in) :: np(ns)
        real, intent(in) :: par(1:6,1:npmax,1:ns)
        integer, intent(inout) :: failures
        integer :: local_count, global_count, s, p

        local_count = 0
        do s = 1, ns
            do p = 1, np(s)
                if (nint(par(4,p,s)) == id) local_count = local_count + 1
            end do
        end do

        call MPI_Allreduce(local_count, global_count, 1, MPI_INTEGER, MPI_SUM, &
            MPI_COMM_WORLD, ierr)

        if (mpi_i == 0 .and. global_count /= expected_count) then
            failures = failures + 1
            write(*,'(a,i0,a,i0,a,i0)') "FAIL H02 global id count id=", id, &
                " actual=", global_count, " expected=", expected_count
        end if

    end subroutine expect_global_id_count

end program test_H_MPI_Exchange
