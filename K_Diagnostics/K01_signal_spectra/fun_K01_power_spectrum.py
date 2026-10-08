"""@file fun_K01_power_spectrum.py
@brief Segment-averaged one-sided power spectral density of one probe.

@details
The one-sided convention doubles every bin except DC and, for even nperseg, the
Nyquist bin. The denominator uses the sum of squared window coefficients;
window must match the argument used to produce the segment FFTs.

@author Zilong PENG (2026/09/02)

@param[in] ffts              array_like, complex (nseg, nfreq) from
                             fun_K01_segment_ffts.
@param[in] sampling_rate_hz  real, sampling rate in Hz.
@param[in] nperseg           integer, segment length used to produce ffts.
@param[in] window            'boxcar' (default) or 'hann', matching the FFTs.
@return numpy.ndarray (nfreq,), density in signal^2 per Hz.
"""

import numpy as np
from K_Diagnostics.K01_signal_spectra.fun_K01_segment_ffts import _window_values


def fun_K01_power_spectrum(ffts, sampling_rate_hz, nperseg, window="boxcar"):
    ffts = np.atleast_2d(np.asarray(ffts))
    nperseg = int(nperseg)
    fs = float(sampling_rate_hz)
    if nperseg < 2 or not np.isfinite(fs) or fs <= 0:
        raise ValueError("positive finite sampling rate and nperseg >= 2 required")
    if ffts.ndim != 2 or not ffts.shape[0] or ffts.shape[1] != nperseg // 2 + 1:
        raise ValueError("ffts must contain complete nonempty rFFT segments")
    weights = _window_values(nperseg, window)
    density = np.mean(np.abs(ffts) ** 2, axis=0) / (fs * np.sum(weights**2))

    scale = np.full(density.shape, 2.0)
    scale[0] = 1.0
    if nperseg % 2 == 0 and density.size == nperseg // 2 + 1:
        scale[-1] = 1.0
    return density * scale
