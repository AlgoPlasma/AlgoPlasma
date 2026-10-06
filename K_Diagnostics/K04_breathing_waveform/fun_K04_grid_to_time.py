"""K04: Periodically interpolate a cycle grid at the supplied phase positions."""

import numpy as np


def fun_K04_grid_to_time(theta, gamma, w):
    """Periodically interpolate a cycle grid at the supplied phase positions.

    theta is a finite real array (N,) in radians. gamma and w are aligned
    arrays (M,) on gamma=2*pi*arange(M)/M, in radians and V respectively.
    Returns C (N,) in V. The repeated endpoint makes interpolation periodic.
    K04 equation (15)."""
    if any(np.iscomplexobj(value) for value in (theta, gamma, w)):
        raise ValueError("Phase, grid and voltage must be real")
    theta, gamma, w = (np.asarray(value, dtype=float) for value in (theta, gamma, w))
    if theta.ndim != 1 or gamma.ndim != 1 or gamma.shape != w.shape or gamma.size < 2:
        raise ValueError("Expected phase (N,) and aligned grid/voltage (M,)")
    if not all(np.isfinite(value).all() for value in (theta, gamma, w)):
        raise ValueError("Phase, grid and voltage must be finite")
    if not np.allclose(gamma, 2*np.pi*np.arange(gamma.size)/gamma.size, rtol=0, atol=1e-12):
        raise ValueError("Expected uniform cycle grid without a repeated endpoint")
    return np.interp(np.remainder(theta, 2*np.pi),
                     np.r_[gamma, 2*np.pi], np.r_[w, w[0]])
