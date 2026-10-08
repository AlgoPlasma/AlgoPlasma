"""K04: Convert bin-center means into positive-order Fourier coefficients."""

import numpy as np


def fun_K04_mean_to_coefficients(mu):
    """Convert bin-center means into positive-order Fourier coefficients.

    mu is a finite real array (B,), with even B >= 4, in V. Returns complex
    a (B//2+1,) in V, including the constant term. The half-bin correction
    places the origin at theta=0 rather than at the first bin center.
    K04 equation (11)."""
    if np.iscomplexobj(mu):
        raise ValueError("Bin means must be real")
    mu = np.asarray(mu, dtype=float)
    if mu.ndim != 1 or mu.size < 4 or mu.size % 2 or not np.isfinite(mu).all():
        raise ValueError("Expected finite bin means with even B >= 4")
    B = len(mu)
    n = np.arange(B//2 + 1)
    return np.fft.rfft(mu)/B * np.exp(-1j*n*np.pi/B)
