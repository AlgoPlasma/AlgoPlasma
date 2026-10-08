"""K04: Accumulate original voltage and sample counts by equal-width phase bins."""

import numpy as np


def fun_K04_put_into_bins(x, theta, B=256):
    """Accumulate original voltage and sample counts by equal-width phase bins.

    x and theta are aligned finite real arrays (N,), in V and radians.
    B is an integer >= 2. Returns S (B,) in V and integer K (B,) counts.
    Do not demean x: the learned waveform includes its baseline.
    K04 equation (8)."""
    if isinstance(B, (bool, np.bool_)) or not isinstance(B, (int, np.integer)) or B < 2:
        raise ValueError("B must be an integer >= 2")
    if np.iscomplexobj(x) or np.iscomplexobj(theta) or not np.isfinite(x).all() or not np.isfinite(theta).all():
        raise ValueError("Expected finite real voltage and phase")
    x, theta = np.asarray(x), np.asarray(theta)
    if x.ndim != 1 or x.shape != theta.shape:
        raise ValueError("Voltage and phase must be aligned 1D arrays")
    b = np.floor(np.remainder(theta, 2*np.pi)*B/(2*np.pi)).astype(int)
    b = np.minimum(b, B-1)
    S = np.bincount(b, weights=x, minlength=B)
    K = np.bincount(b, minlength=B)
    return S, K
