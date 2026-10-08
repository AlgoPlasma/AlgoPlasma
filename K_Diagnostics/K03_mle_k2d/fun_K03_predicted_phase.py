"""@file fun_K03_predicted_phase.py
@brief Cross phase a configuration would measure at every point of the grid.

@details
The forward model is K.chi, the same expression fun_K01_cross_phase measures,
with no sign change. The grid is formed by broadcasting rather than by
materialising two coordinate arrays. This term does not depend on frequency, so
a caller sweeping many frequencies on one geometry should build it once and pass
it to fun_K03_config_log_likelihood; rebuilding it dominates the cost otherwise.

@author Zilong PENG (2026/09/02)

@param[in] chi        array_like (2,), separation vector in metres.
@param[in] kx_values  array_like (nkx,), wavenumber grid in rad/m.
@param[in] ky_values  array_like (nky,), wavenumber grid in rad/m.
@return numpy.ndarray (nky, nkx), the unwrapped predicted phase in radians,
        indexed [iy, ix] to match numpy.meshgrid default ordering.
"""

import numpy as np


def fun_K03_predicted_phase(chi, kx_values, ky_values):
    chi = np.asarray(chi, dtype=np.float64)
    if chi.shape != (2,):
        raise ValueError(f"chi must have shape (2,), got {chi.shape}")
    kx_values = np.asarray(kx_values, dtype=np.float64)
    ky_values = np.asarray(ky_values, dtype=np.float64)
    return kx_values[None, :] * chi[0] + ky_values[:, None] * chi[1]
