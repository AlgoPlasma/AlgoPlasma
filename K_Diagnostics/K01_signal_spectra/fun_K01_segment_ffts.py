"""@file fun_K01_segment_ffts.py
@brief Split a probe record into non-overlapping segments and rFFT each one.

@details
Segments do not overlap. Overlapping them would correlate the phase samples that
fun_K01_phase_mode_statistics treats as independent when estimating the
variance, which would bias the likelihood weights in K03. No window is applied:
a rectangular window is exact for content that is periodic in the segment
length, and records whose content is not bin aligned need a window supplied by
the caller. A trailing partial segment is discarded.

@author Zilong PENG (2026/09/02)

@param[in] signal      array_like (1-D), real probe record.
@param[in] nperseg     integer, samples per segment; the frequency resolution is
                       fs / nperseg.
@param[in] n_segments  integer, optional. Stop after this many segments; the
                       default uses every complete segment.
@param[in] detrend     logical, optional. Remove the mean of each segment before
                       transforming. Default true.
@return numpy.ndarray, complex, shape (n_segments, nperseg // 2 + 1).
"""

import numpy as np


def fun_K01_segment_ffts(signal, nperseg, n_segments=None, detrend=True):
    signal = np.asarray(signal, dtype=np.float64)
    if signal.ndim != 1:
        raise ValueError(f"signal must be 1-D, got shape {signal.shape}")

    nperseg = int(nperseg)
    if nperseg < 2:
        raise ValueError("nperseg must be at least 2")

    available = signal.size // nperseg
    count = available if n_segments is None else min(available, int(n_segments))
    if count <= 0:
        raise ValueError("record is shorter than one segment")

    block = signal[: count * nperseg].reshape(count, nperseg)
    if detrend:
        block = block - block.mean(axis=1, keepdims=True)
    return np.fft.rfft(block, axis=1)
