"""@file fun_K02_fold_wavenumber.py
@brief Fold a projected wavenumber into the Nyquist interval.

@details
Returns k_proj - n 2 pi/|chi| with n from fun_K02_fold_order, which is what a
single pair actually reports: the phase K.chi is observable only modulo 2 pi. A
dispersion branch running past pi/|chi| is therefore broken into a repeating
sawtooth on the Beall map.

@author Zilong PENG (2026/09/02)

@param[in] k_projected  array_like, projected wavenumber in rad/m.
@param[in] chi          array_like (2,), separation vector in metres.
@return numpy.ndarray, the folded wavenumber in rad/m, within +-pi/|chi|.
"""

import numpy as np

from K_Diagnostics.K02_beall.fun_K02_fold_order import fun_K02_fold_order
from K_Diagnostics.K02_beall.fun_K02_separation_magnitude import (
    fun_K02_separation_magnitude,
)


def fun_K02_fold_wavenumber(k_projected, chi):
    magnitude = fun_K02_separation_magnitude(chi)
    k_projected = np.asarray(k_projected, dtype=np.float64)
    return k_projected - fun_K02_fold_order(k_projected, chi) * 2.0 * np.pi / magnitude
