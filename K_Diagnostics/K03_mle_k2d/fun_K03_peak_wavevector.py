"""@file fun_K03_peak_wavevector.py
@brief Locate the maximum of a log-likelihood grid.

@details
Returns the grid point of highest likelihood in both Cartesian and polar form.
The estimate is confined to the grid; alias selection also depends on resolution.
A boundary peak warrants a range check, but does not prove the range is wrong.
Exactly tied grid maxima use the first row-major point; ties are not uniqueness.

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

    if any(a.ndim != 1 or not a.size or not np.all(np.isfinite(a))
           for a in (kx_values, ky_values)):
        raise ValueError("grid axes must be finite nonempty vectors")
    if not np.all(np.isfinite(log_likelihood)) or np.ptp(log_likelihood) == 0:
        raise ValueError("likelihood must be finite and informative on the grid")
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
