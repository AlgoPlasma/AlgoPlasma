"""@file fun_K01_cross_phase.py
@brief Per-segment cross phase and cross-spectral magnitude of a probe pair.

@details
The cross spectrum is X_1 conj(X_2) with the separation chi = r_2 - r_1. For a
plane wave exp(i(K.r - omega t)) sampled with the exp(-i omega t) forward
transform of numpy.fft.rfft this gives arg(X_1 X_2*) = K.chi, wrapped into
(-pi, pi] by numpy.angle. K02 and K03 both use that expression with no sign
change; reversing the probe order negates the phase and mirrors every recovered
wavevector.

@author Zilong PENG (2026/09/02)

@param[in] ffts_1  array_like, complex (nseg, nfreq) for probe 1.
@param[in] ffts_2  array_like, complex (nseg, nfreq) for probe 2, the one
                   displaced by +chi.
@return tuple of numpy.ndarray: the phase arg(X_1 X_2*) and the magnitude
        |X_1 X_2*|, both (nseg, nfreq). The magnitude is the weight used by the
        Beall accumulation in K02.
"""

import numpy as np


def fun_K01_cross_phase(ffts_1, ffts_2):
    ffts_1 = np.atleast_2d(np.asarray(ffts_1))
    ffts_2 = np.atleast_2d(np.asarray(ffts_2))
    if ffts_1.shape != ffts_2.shape:
        raise ValueError("probe spectra must have equal shape")

    cross = ffts_1 * np.conj(ffts_2)
    return np.angle(cross), np.abs(cross)
