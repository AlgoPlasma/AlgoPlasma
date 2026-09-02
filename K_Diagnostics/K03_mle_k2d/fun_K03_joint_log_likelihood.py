"""@file fun_K03_joint_log_likelihood.py
@brief Sum the log-likelihoods of several probe configurations.

@details
One configuration is exactly degenerate: its likelihood is invariant
perpendicular to chi and periodic along it with period 2 pi/|chi|. Summing over
configurations intersects those fringe families, and configurations of different
separation *length* have incommensurate periods, which is what selects a single
aliasing fold order. Changing only the orientation is not enough.

@author Zilong PENG (2026/09/02)

@param[in] configurations  iterable of (chi, delta_theta, variance).
@param[in] kx_values       array_like (nkx,), wavenumber grid in rad/m.
@param[in] ky_values       array_like (nky,), wavenumber grid in rad/m.
@param[in] normalise       logical, optional. Subtract the maximum so the peak
                           sits at zero. Default true.
@return numpy.ndarray (nky, nkx), the joint log-likelihood.
"""

import numpy as np

from K_Diagnostics.K03_mle_k2d.fun_K03_config_log_likelihood import (
    fun_K03_config_log_likelihood,
)


def fun_K03_joint_log_likelihood(configurations, kx_values, ky_values, normalise=True):
    kx_values = np.asarray(kx_values, dtype=np.float64)
    ky_values = np.asarray(ky_values, dtype=np.float64)
    total = np.zeros((ky_values.size, kx_values.size), dtype=np.float64)

    count = 0
    for chi, delta_theta, variance in configurations:
        total += fun_K03_config_log_likelihood(
            chi, delta_theta, variance, kx_values, ky_values
        )
        count += 1
    if count == 0:
        raise ValueError("no configurations supplied")

    if normalise:
        total -= np.max(total)
    return total
