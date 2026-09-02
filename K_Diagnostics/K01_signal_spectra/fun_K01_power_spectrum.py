"""@file fun_K01_power_spectrum.py
@brief Segment-averaged one-sided power spectral density of one probe.

@details
The one-sided convention doubles every bin except DC and, for even nperseg, the
Nyquist bin. The spectra are not corrected for any analysis window, since
fun_K01_segment_ffts applies none.

@author Zilong PENG (2026/09/02)

@param[in] ffts              array_like, complex (nseg, nfreq) from
                             fun_K01_segment_ffts.
@param[in] sampling_rate_hz  real, sampling rate in Hz.
@param[in] nperseg           integer, segment length used to produce ffts.
@return numpy.ndarray (nfreq,), density in signal^2 per Hz.
"""

import numpy as np


def fun_K01_power_spectrum(ffts, sampling_rate_hz, nperseg):
    ffts = np.atleast_2d(np.asarray(ffts))
    nperseg = int(nperseg)
    density = np.mean(np.abs(ffts) ** 2, axis=0) / (float(sampling_rate_hz) * nperseg)

    scale = np.full(density.shape, 2.0)
    scale[0] = 1.0
    if nperseg % 2 == 0 and density.size == nperseg // 2 + 1:
        scale[-1] = 1.0
    return density * scale
