"""@file fun_K02_project_wavenumber.py
@brief Component of a wavevector along a probe separation, K . chi_hat.

@details
A pair is blind to the component perpendicular to its own separation. This
projection is the only part of the wavevector it can carry information about,
and even that only modulo the folding of fun_K02_fold_wavenumber.

@author Zilong PENG (2026/09/02)

@param[in] k_vector  array_like (2,), wavevector in rad/m.
@param[in] chi       array_like (2,), separation vector in metres.
@return float, the projected wavenumber in rad/m.
"""

import numpy as np

from K_Diagnostics.K02_beall.fun_K02_separation_magnitude import (
    fun_K02_separation_magnitude,
)


def fun_K02_project_wavenumber(k_vector, chi):
    magnitude = fun_K02_separation_magnitude(chi)
    k_vector = np.asarray(k_vector, dtype=np.float64)
    if k_vector.shape != (2,):
        raise ValueError(f"k_vector must have shape (2,), got {k_vector.shape}")
    return float(np.dot(k_vector, np.asarray(chi, dtype=np.float64) / magnitude))
