"""K04: Return unwrapped phase phi and cycle position theta for complex z."""

import numpy as np


def fun_K04_mark_position(z):
    """Return unwrapped phase phi and cycle position theta for complex z.

    Input z is a finite, nonzero complex array (N,). Both returned arrays have
    shape (N,) in radians; theta is in [0, 2*pi). The phase origin is retained.
    Very small nonzero amplitudes still require physical quality assessment.
    K04 equations (6)-(7)."""
    z = np.asarray(z, dtype=complex)
    if z.ndim != 1 or z.size < 2 or not np.isfinite(z).all() or np.any(np.abs(z) == 0):
        raise ValueError("Phase requires a finite nonzero 1D complex signal")
    angle = np.angle(z)
    phi = np.unwrap(angle)
    theta = np.remainder(phi, 2*np.pi)
    return phi, theta
