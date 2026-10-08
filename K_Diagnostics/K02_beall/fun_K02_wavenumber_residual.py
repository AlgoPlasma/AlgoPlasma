"""@file fun_K02_wavenumber_residual.py
@brief Circular distance between two wavenumbers on the folded axis.

@details
The wavenumber axis of a single pair is periodic with period 2 pi/|chi|: a value
just below +pi/|chi| and one just above -pi/|chi| are neighbours, not opposites.
Comparing folded wavenumbers with a plain difference therefore reports a full
period of error whenever a value sits near a Nyquist edge, which is an artefact
of the subtraction rather than a real discrepancy.

@author Zilong PENG (2026/09/02)

@param[in] measured   array_like, wavenumbers in rad/m.
@param[in] reference  array_like, wavenumbers in rad/m.
@param[in] chi        array_like (2,), separation vector in metres.
@return numpy.ndarray, absolute circular difference in rad/m, never above
        pi/|chi|.
"""

import numpy as np

from K_Diagnostics.K02_beall.fun_K02_nyquist_wavenumber import (
    fun_K02_nyquist_wavenumber,
)


def fun_K02_wavenumber_residual(measured, reference, chi):
    limit = fun_K02_nyquist_wavenumber(chi)
    period = 2.0 * limit
    difference = np.asarray(measured, dtype=np.float64) - np.asarray(
        reference, dtype=np.float64
    )
    return np.abs((difference + limit) % period - limit)
