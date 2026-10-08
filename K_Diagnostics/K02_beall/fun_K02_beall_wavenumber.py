"""@file fun_K02_beall_wavenumber.py
@brief Convert a cross phase to a wavenumber along the separation.

@details
Returns wrap(theta) / |chi| with the convention of K01: the cross spectrum is
X_1 conj(X_2), so a plane wave gives theta = K.chi and no sign change is needed
here. The result is confined to the Nyquist interval by construction.

@author Zilong PENG (2026/09/02)

@param[in] phase  array_like, cross phase in radians from fun_K01_cross_phase.
@param[in] chi    array_like (2,), separation vector in metres.
@return numpy.ndarray, wavenumber along the separation in rad/m.
"""

from K_Diagnostics.K01_signal_spectra.fun_K01_wrap_to_pi import fun_K01_wrap_to_pi
from K_Diagnostics.K02_beall.fun_K02_separation_magnitude import (
    fun_K02_separation_magnitude,
)


def fun_K02_beall_wavenumber(phase, chi):
    return fun_K01_wrap_to_pi(phase) / fun_K02_separation_magnitude(chi)
