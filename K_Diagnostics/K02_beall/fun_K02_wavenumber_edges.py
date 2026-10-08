"""@file fun_K02_wavenumber_edges.py
@brief Uniform histogram edges spanning the full unaliased wavenumber range.

@details
The range is exactly [-pi/|chi|, +pi/|chi|]. A wider one leaves empty margins
that can never be populated; a narrower one discards wavenumbers the pair can
measure.

@author Zilong PENG (2026/09/02)

@param[in] chi     array_like (2,), separation vector in metres.
@param[in] n_bins  integer, number of histogram bins, at least 2.
@return numpy.ndarray (n_bins + 1,), the bin edges in rad/m.
"""

import numpy as np

from K_Diagnostics.K02_beall.fun_K02_nyquist_wavenumber import (
    fun_K02_nyquist_wavenumber,
)


def fun_K02_wavenumber_edges(chi, n_bins):
    n_bins = int(n_bins)
    if n_bins < 2:
        raise ValueError("n_bins must be at least 2")
    limit = fun_K02_nyquist_wavenumber(chi)
    return np.linspace(-limit, limit, n_bins + 1, dtype=np.float64)
