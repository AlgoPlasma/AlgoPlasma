"""@file fun_K01_phase_mode_statistics.py
@brief Liu histogram-mode mean estimate and shifted phase variance.

@details
A distribution of wrapped phases can straddle the +-pi branch cut, where a plain
arithmetic mean collapses towards zero. This routine locates the mode on an
nbins histogram and moves the branch cut opposite it:

    theta_bar = theta_mode
    sigma^2   = var(wrap(theta_i - theta_mode), ddof=1) + 1e-12

This follows Liu and Jorns (AIAA 2025-1293, II.E): use the histogram mode as a
proxy for the mean. ddof=1 is our explicit convention, not specified by Liu.
The first modal bin wins an exact tie; bin choice matters. Nonfinite samples
are omitted. Fewer than two valid samples gives NaN mean and variance. The
variance describes individual samples, not the mean. The positive floor only
regularises valid noiseless samples; it cannot validate missing measurements.

@author Zilong PENG (2026/09/02)

@param[in] phase  array_like, wrapped phases (nseg,) or (nseg, nfreq) from
                  fun_K01_cross_phase.
@param[in] nbins  integer, optional. Histogram bins used to locate the mode.
                  Default 60.
@return tuple of numpy.ndarray: the mean phase and the variance, scalar for 1-D
        input and (nfreq,) for 2-D input.
"""

import numpy as np

from K_Diagnostics.K01_signal_spectra.fun_K01_wrap_to_pi import fun_K01_wrap_to_pi


def fun_K01_phase_mode_statistics(phase, nbins=60):
    phase = np.asarray(phase, dtype=np.float64)
    scalar = phase.ndim == 1
    if scalar:
        phase = phase[:, None]
    if phase.ndim != 2:
        raise ValueError("phase must be 1-D or 2-D (nseg, nfreq)")

    n_segments, n_freq = phase.shape
    if n_segments < 2:
        raise ValueError("need at least two segments to estimate a variance")

    nbins = int(nbins)
    if nbins < 2:
        raise ValueError("nbins must be at least 2")

    width = 2.0 * np.pi / nbins
    finite = np.isfinite(phase)
    valid_counts = finite.sum(axis=0)
    wrapped = fun_K01_wrap_to_pi(np.where(finite, phase, 0.0))
    index = np.clip(np.floor((wrapped + np.pi) / width), 0, nbins - 1).astype(np.int64)
    offsets = np.arange(n_freq, dtype=np.int64)[None, :] * nbins
    counts = np.bincount((offsets + index)[finite], minlength=n_freq * nbins)
    mode = -np.pi + (np.argmax(counts.reshape(n_freq, nbins), axis=1) + 0.5) * width

    shifted = fun_K01_wrap_to_pi(wrapped - mode[None, :])
    shifted = np.where(finite, shifted, 0.0)
    center = shifted.sum(axis=0) / np.maximum(valid_counts, 1)
    squares = np.where(finite, (shifted - center)**2, 0.0).sum(axis=0)
    variance = squares / np.maximum(valid_counts - 1, 1) + 1.0e-12
    mean_phase = np.where(valid_counts >= 2, mode, np.nan)
    variance = np.where(valid_counts >= 2, variance, np.nan)

    if scalar:
        return mean_phase[0], variance[0]
    return mean_phase, variance
