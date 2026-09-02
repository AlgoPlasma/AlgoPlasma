"""@file fun_K01_coherence.py
@brief Magnitude-squared coherence of a probe pair.

@details
With n independent segments the coherence of two uncorrelated signals does not
average to zero but to 1/n. That floor, not zero, is the reference against which
an unpopulated frequency band should be judged.

@author Zilong PENG (2026/09/02)

@param[in] ffts_1  array_like, complex (nseg, nfreq) for probe 1.
@param[in] ffts_2  array_like, complex (nseg, nfreq) for probe 2, same shape.
@return numpy.ndarray (nfreq,), coherence in [0, 1].
"""

import numpy as np


def fun_K01_coherence(ffts_1, ffts_2):
    ffts_1 = np.atleast_2d(np.asarray(ffts_1))
    ffts_2 = np.atleast_2d(np.asarray(ffts_2))
    if ffts_1.shape != ffts_2.shape:
        raise ValueError(
            f"probe spectra must have equal shape, got {ffts_1.shape} and {ffts_2.shape}"
        )

    cross = np.mean(ffts_1 * np.conj(ffts_2), axis=0)
    auto_1 = np.mean(np.abs(ffts_1) ** 2, axis=0)
    auto_2 = np.mean(np.abs(ffts_2) ** 2, axis=0)
    return np.clip(np.abs(cross) ** 2 / (auto_1 * auto_2 + 1.0e-300), 0.0, 1.0)
