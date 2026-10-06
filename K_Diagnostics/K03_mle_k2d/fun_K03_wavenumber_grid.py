"""@file fun_K03_wavenumber_grid.py
@brief Uniform search grid on [-k_range, +k_range].

@details
The likelihood is maximised on a grid, so the estimate is confined to it: the
range must contain the true wavevector. Resolution must be checked for both
peak location and alias selection; a boundary peak warrants a range check.

@author Zilong PENG (2026/09/02)

@param[in] k_range_rad_m  real, half-width of the grid in rad/m, positive.
@param[in] n_grid         integer, points along the axis, at least 2.
@return numpy.ndarray (n_grid,), the grid values in rad/m.
"""

import numpy as np


def fun_K03_wavenumber_grid(k_range_rad_m, n_grid):
    k_range_rad_m = float(k_range_rad_m)
    if int(n_grid) != n_grid:
        raise ValueError("n_grid must be an integer")
    n_grid = int(n_grid)
    if not np.isfinite(k_range_rad_m) or k_range_rad_m <= 0.0:
        raise ValueError("k_range_rad_m must be positive")
    if n_grid < 2:
        raise ValueError("n_grid must be at least 2")
    return np.linspace(-k_range_rad_m, k_range_rad_m, n_grid, dtype=np.float64)
