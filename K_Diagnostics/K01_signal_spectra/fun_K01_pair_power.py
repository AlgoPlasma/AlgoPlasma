"""Per-segment Beall weight: (|X1|**2 + |X2|**2)/2 (Liu 2025, Eq. 2).

The two FFTs must use identical windows and normalization. These are raw FFT
powers, not a PSD. Phase validity is checked separately by cross_phase/K02;
positive power in only one channel cannot define a cross phase.
"""

import numpy as np


def fun_K01_pair_power(ffts_1, ffts_2):
    first, second = np.atleast_2d(ffts_1), np.atleast_2d(ffts_2)
    if first.shape != second.shape:
        raise ValueError("probe spectra must have equal shape")
    with np.errstate(invalid="ignore", over="ignore"):
        return 0.5 * (np.abs(first)**2 + np.abs(second)**2)
