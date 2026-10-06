"""K04: Keep a positive band of a full FFT and reconstruct its complex signal."""

import numpy as np


def fun_K04_make_complex_signal(F, f, band=(25e3, 55e3)):
    """Keep a positive band of a full FFT and reconstruct its complex signal.

    F and f are aligned (N,) arrays from find_frequency; band is (lo, hi) Hz.
    Returns F_hat and z, both complex (N,). A real cosine of amplitude A has
    positive-frequency complex amplitude A/2; this routine does not double it.
    K04 equation (4)."""
    F, f = np.asarray(F), np.asarray(f, dtype=float)
    if F.ndim != 1 or F.shape != f.shape or F.size < 2 or not np.isfinite(F).all() or not np.isfinite(f).all():
        raise ValueError("Expected finite aligned FFT and frequency arrays")
    lo, hi = band
    if not 0 < lo < hi <= np.max(f):
        raise ValueError("Choose a positive band below fs/2")
    keep = (f >= lo) & (f <= hi)
    F_hat = np.where(keep, F, 0.0)
    if not np.any(np.abs(F_hat) > 0):
        raise ValueError("No signal from which to read phase")
    z = np.fft.ifft(F_hat)
    return F_hat, z
