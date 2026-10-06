"""K04: Evaluate retained harmonics on a dense uniform cycle grid."""

import numpy as np


def fun_K04_coefficients_to_grid(a, f0, fs, cutoff=3e6, M=4096):
    """Evaluate retained harmonics on a dense uniform cycle grid.

    a is complex (B//2+1,) from mean_to_coefficients; f0, fs and cutoff are
    in Hz. M >= 2 is the integer grid size. H=floor(cutoff/f0) must be
    strictly below B/2 and M/2; cutoff must be below fs/2. Returns gamma (M,)
    in radians, w (M,) in V and integer H. DC-only reconstruction is allowed.
    The cutoff is a nominal harmonic-order limit, not a time-domain lowpass.
    K04 equations (12)-(14)."""
    a = np.asarray(a, dtype=complex)
    if a.ndim != 1 or a.size < 3 or not np.isfinite(a).all():
        raise ValueError("Expected finite positive-order coefficients")
    if not np.isfinite([f0, fs, cutoff]).all() or fs <= 0:
        raise ValueError("Frequencies must be finite and fs positive")
    if isinstance(M, (bool, np.bool_)) or not isinstance(M, (int, np.integer)) or M < 2:
        raise ValueError("M must be an integer >= 2")
    if not 0 < cutoff < fs/2 or f0 <= 0:
        raise ValueError("Nominal cutoff must be positive and below fs/2")
    H = int(np.floor(cutoff/f0))
    if H >= len(a)-1 or 2*H >= M:
        raise ValueError("Increase phase bins/grid, or lower the cutoff")
    gamma = 2*np.pi*np.arange(M)/M
    n = np.arange(1, H+1)
    waves = np.exp(1j*np.outer(gamma, n))
    w = a[0].real + 2*np.real(waves @ a[n])
    return gamma, w, H
