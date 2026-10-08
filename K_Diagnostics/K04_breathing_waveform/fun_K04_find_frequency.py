"""K04: Find the strongest positive FFT bin after removing the record mean."""

import numpy as np


def fun_K04_find_frequency(x, fs, search=(35e3, 45e3)):
    """Find the strongest positive FFT bin after removing the record mean.

    Parameters: x, finite real array (N,); fs, positive Hz; search, (lo, hi) Hz.
    Returns F (N,) complex, f (N,) Hz, and scalar f0 in Hz. No window or
    segmentation is applied. The DC removal is only for phase estimation.
    K04 equations (2)-(3)."""
    if np.iscomplexobj(x) or not np.isfinite(fs) or fs <= 0:
        raise ValueError("Expected real voltage and a positive finite sampling rate")
    x = np.asarray(x, dtype=float)
    lo, hi = search
    if x.ndim != 1 or x.size < 2 or not np.isfinite(x).all():
        raise ValueError("Expected a finite 1D record")
    if not 0 < lo < hi < fs/2:
        raise ValueError("Search band must lie below fs/2")
    F = np.fft.fft(x - x.mean())
    f = np.fft.fftfreq(x.size, d=1/fs)
    candidates = np.flatnonzero((f >= lo) & (f <= hi))
    if candidates.size == 0:
        raise ValueError("No frequency points in search band")
    k0 = candidates[np.argmax(np.abs(F[candidates])**2)]
    return F, f, float(f[k0])
