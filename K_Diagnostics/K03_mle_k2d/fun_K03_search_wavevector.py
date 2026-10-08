"""@file fun_K03_search_wavevector.py
@brief Exhaustive uniform-grid MLE, with bounded-memory row blocks.
@author Zilong PENG (2026/09/02)

Every point in [-k_range_rad_m, k_range_rad_m]**2 is evaluated. No local
refinement is used. The answer maximizes the discrete grid, NOT the continuous
likelihood: repeat at finer resolution to check alias selection. Small steps
relative to 2*pi/max(|chi|) alone do not guarantee the correct alias.

Arguments: configurations = (chi, phase, variance) triples; n_grid (default
1501) points per axis; block_rows (default 32) controls memory, not resolution.
Returns the peak dictionary plus grid_step, n_grid, boundary, valid_configurations,
and tied_grid_points. peak_log_likelihood is the raw (unnormalised) maximum.
"""

import numpy as np

from K_Diagnostics.K01_signal_spectra.fun_K01_wrap_to_pi import fun_K01_wrap_to_pi
from K_Diagnostics.K03_mle_k2d.fun_K03_joint_log_likelihood import _valid_configurations
from K_Diagnostics.K03_mle_k2d.fun_K03_wavenumber_grid import fun_K03_wavenumber_grid


def fun_K03_search_wavevector(configurations, k_range_rad_m, n_grid=1501, block_rows=32):
    configs = _valid_configurations(configurations)
    axis = fun_K03_wavenumber_grid(k_range_rad_m, n_grid)
    if int(block_rows) != block_rows or block_rows < 1:
        raise ValueError("block_rows must be a positive integer")
    best, lowest, best_index, ties = -np.inf, np.inf, (0, 0), 0
    for first in range(0, axis.size, int(block_rows)):
        ys = axis[first:first + int(block_rows), None]
        total = np.zeros((ys.size, axis.size), dtype=np.float64)
        for chi, theta, variance in configs:
            residual = fun_K01_wrap_to_pi(chi[0] * axis[None, :] + chi[1] * ys - theta)
            total -= 0.5 * residual**2 / variance
        if not np.all(np.isfinite(total)):
            raise ValueError("nonfinite likelihood; check scales and variances")
        lowest = min(lowest, float(total.min()))
        iy, ix = np.unravel_index(int(np.argmax(total)), total.shape)
        value = float(total[iy, ix])
        if value > best:
            best, best_index, ties = value, (first + iy, ix), int(np.sum(total == value))
        elif value == best:
            ties += int(np.sum(total == value))
    if best == lowest:
        raise ValueError("likelihood is uninformative on the grid")
    iy, ix = best_index
    kx, ky = float(axis[ix]), float(axis[iy])
    return {
        "kx": kx, "ky": ky, "k_magnitude": float(np.hypot(kx, ky)),
        "angle_deg": float(np.degrees(np.arctan2(ky, kx))),
        "peak_log_likelihood": best, "grid_step": float(axis[1] - axis[0]),
        "n_grid": int(axis.size), "valid_configurations": len(configs),
        "boundary": bool(ix in (0, axis.size - 1) or iy in (0, axis.size - 1)),
        "tied_grid_points": ties,
    }
