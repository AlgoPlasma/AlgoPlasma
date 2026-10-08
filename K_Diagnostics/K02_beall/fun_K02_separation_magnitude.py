"""@file fun_K02_separation_magnitude.py
@brief Length of a probe separation vector, with validation.

@details
Every routine in this unit divides by |chi|, so the shape check and the
zero-length rejection are done here once rather than repeated in each of them.

@author Zilong PENG (2026/09/02)

@param[in] chi  array_like (2,), separation vector in metres.
@return float, the length |chi| in metres.
"""

import numpy as np


def fun_K02_separation_magnitude(chi):
    chi = np.asarray(chi, dtype=np.float64)
    if chi.shape != (2,):
        raise ValueError(f"chi must have shape (2,), got {chi.shape}")
    magnitude = float(np.hypot(chi[0], chi[1]))
    if not np.isfinite(magnitude) or magnitude <= 0.0:
        raise ValueError("chi must have finite non-zero length")
    return magnitude
