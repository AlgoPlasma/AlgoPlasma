"""@file fun_K02_separation_vector.py
@brief Build a probe separation vector from a spacing and an orientation.

@details
The separation is chi = r_2 - r_1, with the orientation measured from the +x
axis. Reversing it negates every cross phase and mirrors every recovered
wavenumber, so the sense of this vector fixes the sign convention of the whole
module family.

@author Zilong PENG (2026/09/02)

@param[in] spacing_m  real, probe separation |chi| in metres, positive.
@param[in] angle_rad  real, orientation from the +x axis in radians.
@return numpy.ndarray (2,), the separation vector in metres.
"""

import numpy as np


def fun_K02_separation_vector(spacing_m, angle_rad):
    spacing_m = float(spacing_m)
    if spacing_m <= 0.0:
        raise ValueError("spacing_m must be positive")
    return np.array(
        [spacing_m * np.cos(angle_rad), spacing_m * np.sin(angle_rad)],
        dtype=np.float64,
    )
