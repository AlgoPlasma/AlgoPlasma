"""@file fun_K02_nyquist_wavenumber.py
@brief Largest wavenumber a probe separation can resolve, pi / |chi|.

@details
A pair observes the phase K.chi only modulo 2 pi, so wavenumbers outside
[-pi/|chi|, +pi/|chi|] cannot be told apart from their folded images. The
corresponding frequency limit for a branch of speed v is v / (2 |chi|).

@author Zilong PENG (2026/09/02)

@param[in] chi  array_like (2,), separation vector in metres.
@return float, the Nyquist wavenumber in rad/m.
"""

import numpy as np

from K_Diagnostics.K02_beall.fun_K02_separation_magnitude import (
    fun_K02_separation_magnitude,
)


def fun_K02_nyquist_wavenumber(chi):
    return np.pi / fun_K02_separation_magnitude(chi)
