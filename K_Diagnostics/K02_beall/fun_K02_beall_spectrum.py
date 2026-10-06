"""@file fun_K02_beall_spectrum.py
@brief Accumulate the Beall statistical dispersion spectrum S(k, f).

@details
Each valid (segment, frequency) sample contributes its mean pair auto-power to the
single wavenumber bin holding wrap(theta)/|chi|, and the histogram is divided by
the segment count. That is what makes the estimator statistical: incoherent
segments spread their power along the wavenumber axis while coherent ones
concentrate it. The estimator is a histogram, so it needs many more segments
than a mean phase does before a peak is meaningful.

Reference: J. M. Beall, Y. C. Kim, and E. J. Powers, J. Appl. Phys. 53(6),
3933-3940 (1982).

@author Zilong PENG (2026/09/02)

@param[in] phase           array_like (nseg, nfreq), cross phase in radians.
@param[in] magnitude       array_like (nseg, nfreq), mean pair auto-power
                           (|X1|^2+|X2|^2)/2. Historical argument name retained.
@param[in] frequencies_hz  array_like (nfreq,), centre frequency of each bin.
@param[in] chi             array_like (2,), separation vector in metres.
@param[in] k_edges         array_like, wavenumber histogram edges in rad/m.
@param[in] f_edges         array_like, frequency histogram edges in Hz.
@return dict with keys spectrum (nf, nk), k_centers, f_centers, k_nyquist and
        segments.
"""

import numpy as np

from K_Diagnostics.K02_beall.fun_K02_beall_wavenumber import fun_K02_beall_wavenumber
from K_Diagnostics.K02_beall.fun_K02_nyquist_wavenumber import (
    fun_K02_nyquist_wavenumber,
)


def fun_K02_beall_spectrum(phase, magnitude, frequencies_hz, chi, k_edges, f_edges):
    phase = np.atleast_2d(np.asarray(phase, dtype=np.float64))
    magnitude = np.atleast_2d(np.asarray(magnitude, dtype=np.float64))
    if phase.shape != magnitude.shape:
        raise ValueError("phase and magnitude must have the same shape")

    frequencies_hz = np.asarray(frequencies_hz, dtype=np.float64)
    if frequencies_hz.shape[0] != phase.shape[1]:
        raise ValueError(
            f"expected {phase.shape[1]} frequencies, got {frequencies_hz.shape[0]}"
        )

    k_edges = np.asarray(k_edges, dtype=np.float64)
    f_edges = np.asarray(f_edges, dtype=np.float64)
    wavenumber = fun_K02_beall_wavenumber(phase, chi)
    frequency = np.broadcast_to(frequencies_hz[None, :], wavenumber.shape)
    valid = (np.isfinite(wavenumber) & np.isfinite(frequency)
             & np.isfinite(magnitude) & (magnitude > 0))

    histogram, _, _ = np.histogram2d(
        frequency[valid],
        wavenumber[valid],
        bins=(f_edges, k_edges),
        weights=magnitude[valid],
    )
    return {
        "spectrum": histogram / max(phase.shape[0], 1),
        "k_centers": 0.5 * (k_edges[:-1] + k_edges[1:]),
        "f_centers": 0.5 * (f_edges[:-1] + f_edges[1:]),
        "k_nyquist": fun_K02_nyquist_wavenumber(chi),
        "segments": int(phase.shape[0]),
    }
