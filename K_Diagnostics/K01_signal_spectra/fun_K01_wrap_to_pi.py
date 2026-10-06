"""@file fun_K01_wrap_to_pi.py
@brief Wrap angles into the interval [-pi, pi].

@details
Uses the subtract-and-round form rather than a modulo. The two agree to a few
times machine epsilon, but the modulo is several times slower and this routine
runs over full wavenumber grids inside the K03 likelihood. The interval is
closed at both ends: an input of exactly +-pi is returned unchanged, whereas a
modulo would fold +pi to -pi. Measured phases never land there exactly.

@author Zilong PENG (2026/09/02)

@param[in] values  array_like, angles in radians.
@return numpy.ndarray, the angles wrapped to [-pi, pi].
"""

import numpy as np


def fun_K01_wrap_to_pi(values):
    values = np.asarray(values, dtype=np.float64)
    return values - (2.0 * np.pi) * np.round(values / (2.0 * np.pi))
