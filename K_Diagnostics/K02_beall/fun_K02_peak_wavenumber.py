"""@file fun_K02_peak_wavenumber.py
@brief Peak wavenumber of a Beall spectrum at each frequency.

@details
Takes the histogram maximum, a finite-sample mode. Its scatter is set by the
phase statistics and the segment count, not by the bin width, so a spectrum
built from few segments returns the strongest single sample rather than a peak.
Frequencies that received no power return nan.

@author Zilong PENG (2026/09/02)

@param[in] spectrum   array_like (nf, nk) from fun_K02_beall_spectrum.
@param[in] k_centers  array_like (nk,), wavenumber bin centres in rad/m.
@return numpy.ndarray (nf,), peak wavenumber in rad/m, nan where empty.
"""

import numpy as np


def fun_K02_peak_wavenumber(spectrum, k_centers):
    spectrum = np.asarray(spectrum, dtype=np.float64)
    k_centers = np.asarray(k_centers, dtype=np.float64)
    if spectrum.ndim != 2 or spectrum.shape[1] != k_centers.size:
        raise ValueError("spectrum must have shape (nf, k_centers.size)")
    peak = k_centers[np.argmax(spectrum, axis=1)]
    return np.where(spectrum.sum(axis=1) > 0.0, peak, np.nan)
