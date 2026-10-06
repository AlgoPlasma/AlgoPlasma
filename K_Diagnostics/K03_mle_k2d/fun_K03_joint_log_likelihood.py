"""@file fun_K03_joint_log_likelihood.py
@brief Sum the log-likelihoods of several probe configurations.

@details
One configuration is exactly degenerate: its likelihood is invariant
perpendicular to chi and periodic along it with period 2 pi/|chi|. Summing over
configurations intersects those fringe families. Equal lengths with suitably
different directions can resolve aliases; different lengths do not guarantee
uniqueness. Exact aliases satisfy chi_i.dot(delta_K) in 2*pi*Z for every i.
Rank two is necessary for 2D inference, but not sufficient for a unique alias.
Nonfinite phases/variances and nonpositive variances are omitted. Fewer than
two independent valid baselines raises ValueError rather than returning a ridge.

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

    for chi, delta_theta, variance in _valid_configurations(configurations):
        total += fun_K03_config_log_likelihood(
            chi, delta_theta, variance, kx_values, ky_values
        )

    if normalise:
        total -= np.max(total)
    return total


def _valid_configurations(configurations):
    valid = []
    for chi, theta, variance in configurations:
        chi = np.asarray(chi, dtype=np.float64)
        if chi.shape != (2,) or not np.all(np.isfinite(chi)) or not np.any(chi):
            raise ValueError("each chi must be a finite nonzero 2-vector")
        if np.isfinite(theta) and np.isfinite(variance) and variance > 0:
            valid.append((chi, float(theta), float(variance)))
    if len(valid) < 2 or np.linalg.matrix_rank(np.array([c[0] for c in valid])) < 2:
        raise ValueError("need at least two independent valid baselines for 2D inference")
    return valid
