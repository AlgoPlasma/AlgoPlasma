"""@file fun_K01_phase_mode_statistics.py
@brief Mode-referenced mean and variance of wrapped phase samples.

@details
A distribution of wrapped phases can straddle the +-pi branch cut, where a plain
arithmetic mean collapses towards zero. This routine locates the mode on an
nbins histogram, moves the branch cut opposite it, and averages there:

    theta_bar = theta_mode + < wrap(theta_i - theta_mode) >
    sigma^2   = var(wrap(theta_i - theta_mode), ddof=1) + 1e-12

The returned mean is not re-wrapped, so it may leave (-pi, pi] by up to one
histogram bin when the mode sits on the cut. The variance is that of an
individual sample, not of the mean, and the floor keeps noiseless input from
dividing by zero in the K03 likelihood.

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
    index = np.clip(np.floor((phase + np.pi) / width), 0, nbins - 1).astype(np.int64)
    offsets = np.arange(n_freq, dtype=np.int64)[None, :] * nbins
    counts = np.bincount((offsets + index).ravel(), minlength=n_freq * nbins)
    mode = -np.pi + (np.argmax(counts.reshape(n_freq, nbins), axis=1) + 0.5) * width

    shifted = fun_K01_wrap_to_pi(phase - mode[None, :])
    mean_phase = mode + shifted.mean(axis=0)
    variance = shifted.var(axis=0, ddof=1) + 1.0e-12

    if scalar:
        return mean_phase[0], variance[0]
    return mean_phase, variance
