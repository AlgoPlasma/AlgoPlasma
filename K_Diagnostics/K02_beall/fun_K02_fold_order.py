"""@file fun_K02_fold_order.py
@brief Aliasing fold order of a projected wavenumber.

@details
The integer n such that k_proj - n 2 pi/|chi| lands inside the Nyquist interval.
This routine requires a known projected wavenumber; a single pair's wrapped
phase alone cannot determine the fold order. Complementary baseline geometries
can recover it in K03 when identifiable within the search domain. Different
lengths are neither necessary nor sufficient for unique alias selection.

@author Zilong PENG (2026/09/02)

@param[in] k_projected  array_like, projected wavenumber in rad/m, scalar or
                        array.
@param[in] chi          array_like (2,), separation vector in metres.
@return int for scalar input, numpy.ndarray of int64 otherwise.
"""

import numpy as np

from K_Diagnostics.K02_beall.fun_K02_separation_magnitude import (
    fun_K02_separation_magnitude,
)


def fun_K02_fold_order(k_projected, chi):
    magnitude = fun_K02_separation_magnitude(chi)
    order = np.rint(
        np.asarray(k_projected, dtype=np.float64) * magnitude / (2.0 * np.pi)
    )
    return order.astype(np.int64) if order.ndim else int(order)
