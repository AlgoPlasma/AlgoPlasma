"""@file fun_K03_peak_wavevector.py
@brief Locate the maximum of a log-likelihood grid.

@details
Returns the grid point of highest likelihood in both Cartesian and polar form.
The estimate is confined to the grid, so the accuracy has a floor of half a grid
step and a peak on the boundary means the search range was too narrow.

@author Zilong PENG (2026/09/02)

@param[in] log_likelihood  array_like (nky, nkx) from
                           fun_K03_joint_log_likelihood.
@param[in] kx_values       array_like (nkx,), wavenumber grid in rad/m.
@param[in] ky_values       array_like (nky,), wavenumber grid in rad/m.
@return dict with keys kx, ky, k_magnitude, angle_deg and peak_log_likelihood.
"""

import numpy as np


def fun_K03_peak_wavevector(log_likelihood, kx_values, ky_values):
    log_likelihood = np.asarray(log_likelihood, dtype=np.float64)
    kx_values = np.asarray(kx_values, dtype=np.float64)
    ky_values = np.asarray(ky_values, dtype=np.float64)
    if log_likelihood.shape != (ky_values.size, kx_values.size):
        raise ValueError(
            f"log_likelihood shape {log_likelihood.shape} does not match "
            f"({ky_values.size}, {kx_values.size})"
        )

    iy, ix = np.unravel_index(int(np.argmax(log_likelihood)), log_likelihood.shape)
    kx = float(kx_values[ix])
    ky = float(ky_values[iy])
    return {
        "kx": kx,
        "ky": ky,
        "k_magnitude": float(np.hypot(kx, ky)),
        "angle_deg": float(np.degrees(np.arctan2(ky, kx))),
        "peak_log_likelihood": float(log_likelihood[iy, ix]),
    }
