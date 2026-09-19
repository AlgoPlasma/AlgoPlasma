"""@file fun_K03_search_wavevector.py
@brief Coarse grid search followed by a local refinement.

@details
A single uniform grid cannot serve a wide band: it must reach the largest
wavevector present while still resolving the smallest, and covering three
decades at useful resolution would need thousands of points per axis. This
searches a coarse grid over the whole range, then rebuilds a fine grid in a
small window around the coarse peak.

The coarse stage only has to pick the right fringe, not the right point within
it. Because the fringe period 2 pi/|chi| decreases as the separation grows,
the longest separation sets the smallest period and therefore the strictest
grid-spacing requirement. The coarse step must stay well below that period;
check this condition first if a result looks locked to the wrong aliasing fold.

@author Zilong PENG (2026/09/02)

@param[in] configurations  iterable of (chi, delta_theta, variance). It is
                           materialised, since it is traversed twice.
@param[in] k_range_rad_m   real, half-width of the coarse grid in rad/m; it must
                           contain the true wavevector.
@param[in] n_coarse        integer, optional. Points per axis in the first
                           stage. Default 401.
@param[in] n_fine          integer, optional. Points per axis in the second
                           stage. Default 201.
@param[in] refine_span     real, optional. Coarse steps kept on each side of the
                           coarse peak. Default 2.0.
@return dict as fun_K03_peak_wavevector, with coarse_step and fine_step added.
"""

import numpy as np

from K_Diagnostics.K03_mle_k2d.fun_K03_joint_log_likelihood import (
    fun_K03_joint_log_likelihood,
)
from K_Diagnostics.K03_mle_k2d.fun_K03_peak_wavevector import fun_K03_peak_wavevector
from K_Diagnostics.K03_mle_k2d.fun_K03_wavenumber_grid import fun_K03_wavenumber_grid


def fun_K03_search_wavevector(
    configurations, k_range_rad_m, n_coarse=401, n_fine=201, refine_span=2.0
):
    configurations = list(configurations)
    coarse = fun_K03_wavenumber_grid(k_range_rad_m, n_coarse)
    coarse_peak = fun_K03_peak_wavevector(
        fun_K03_joint_log_likelihood(configurations, coarse, coarse), coarse, coarse
    )

    step = float(coarse[1] - coarse[0])
    window = float(refine_span) * step
    fine_x = np.linspace(
        coarse_peak["kx"] - window, coarse_peak["kx"] + window, int(n_fine)
    )
    fine_y = np.linspace(
        coarse_peak["ky"] - window, coarse_peak["ky"] + window, int(n_fine)
    )

    result = fun_K03_peak_wavevector(
        fun_K03_joint_log_likelihood(configurations, fine_x, fine_y), fine_x, fine_y
    )
    result["coarse_step"] = step
    result["fine_step"] = float(fine_x[1] - fine_x[0])
    return result
