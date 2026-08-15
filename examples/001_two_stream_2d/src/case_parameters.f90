module two_stream_parameters
    implicit none

    integer, parameter :: nx = 64, ny = 64
    integer, parameter :: nppc_x = 8, nppc_y = 8
    integer, parameter :: np_beam = nx*ny*nppc_x*nppc_y
    integer, parameter :: np = 2*np_beam
    integer, parameter :: nt = 800
    integer, parameter :: field_stride = 5, particle_stride = 50

    real, parameter :: dx = 1.0, dy = 1.0
    real, parameter :: lx = nx*dx, ly = ny*dy
    real, parameter :: dt = 0.05
    ! Standard deviation of each Gaussian component: v_te=sqrt(k_B*T_e/m_e).
    real, parameter :: thermal_speed = 1.0
    real, parameter :: drift_speed = 3.0
    real, parameter :: particle_weight = real(nx*ny)/real(np)
    real, parameter :: charge = -1.0, mass = 1.0, eps0 = 1.0
    real, parameter :: perturbation = 0.005
    integer, parameter :: mode_x = 2, mode_y = 1
    integer, parameter :: random_seed_base = 20260810
    real, parameter :: solver_tolerance = 1.0e-10
    real, parameter :: pi2 = 6.2831853071795864769

    real, parameter :: initial_half_push = -charge*dt/(4.0*mass)
    real, parameter :: full_push = charge*dt/(2.0*mass)
end module two_stream_parameters

