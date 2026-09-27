"""@file fun_K01_segment_ffts.py
@brief Split a probe record into non-overlapping segments and rFFT each one.

@details
Segments do not overlap. Overlapping them would correlate the phase samples that
fun_K01_phase_mode_statistics treats as independent when estimating the
variance. A rectangular window is the default for bin-aligned synthetic data;
use window='hann' to reduce leakage for non-bin-aligned records. Windowing does
not guarantee unbiased cross phase. A trailing partial segment is discarded.

@author Zilong PENG (2026/09/02)

@param[in] signal      array_like (1-D), real probe record.
@param[in] nperseg     integer, samples per segment; the frequency resolution is
                       fs / nperseg.
@param[in] n_segments  integer, optional. Stop after this many segments; the
                       default uses every complete segment.
@param[in] detrend     logical, optional. Remove the mean of each segment before
                       transforming. Default true.
@param[in] window      'boxcar' (default) or 'hann' (symmetric numpy.hanning).
@return numpy.ndarray, complex, shape (n_segments, nperseg // 2 + 1).
"""

import numpy as np


def fun_K01_segment_ffts(signal, nperseg, n_segments=None, detrend=True, window="boxcar"):
    signal = np.asarray(signal, dtype=np.float64)
    if signal.ndim != 1:
        raise ValueError(f"signal must be 1-D, got shape {signal.shape}")

    nperseg = int(nperseg)
    if nperseg < 2:
        raise ValueError("nperseg must be at least 2")
    weights = _window_values(nperseg, window)

    available = signal.size // nperseg
    count = available if n_segments is None else min(available, int(n_segments))
    if count <= 0:
        raise ValueError("record is shorter than one segment")

    block = signal[: count * nperseg].reshape(count, nperseg)
    if detrend:
        block = block - block.mean(axis=1, keepdims=True)
    return np.fft.rfft(block * weights, axis=1)


def _window_values(nperseg, window):
    if window == "boxcar":
        return np.ones(nperseg)
    if window == "hann" and nperseg >= 3:
        return np.hanning(nperseg)
    raise ValueError("window must be 'boxcar', or 'hann' with nperseg >= 3")
