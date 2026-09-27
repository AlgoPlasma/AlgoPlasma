"""@file fun_K03_config_log_likelihood.py
@brief Log-likelihood of one probe configuration over the wavenumber grid.

@details
Models the measured mean phase as Gaussian about the plane-wave prediction:

    ln L(K) = -0.5 wrap(K.chi - theta_bar)^2 / sigma^2

The residual is wrapped before squaring. That step is not a numerical
convenience: it is what makes an aliased configuration contribute a periodic
family of ridges rather than a single one, so the folded information stays in
the likelihood and can be resolved by the other configurations.

@author Zilong PENG (2026/09/02)

@param[in] chi          array_like (2,), separation vector in metres.
@param[in] delta_theta  real, measured mean cross phase in radians.
@param[in] variance     real, phase variance in rad^2, positive.
@param[in] kx_values    array_like (nkx,), wavenumber grid in rad/m.
@param[in] ky_values    array_like (nky,), wavenumber grid in rad/m.
@param[in] prediction   array_like (nky, nkx), optional. Precomputed
                        fun_K03_predicted_phase for this chi and grid.
@return numpy.ndarray (nky, nkx), the unnormalised log-likelihood.
"""

import numpy as np

from K_Diagnostics.K01_signal_spectra.fun_K01_wrap_to_pi import fun_K01_wrap_to_pi
from K_Diagnostics.K03_mle_k2d.fun_K03_predicted_phase import fun_K03_predicted_phase


def fun_K03_config_log_likelihood(
    chi, delta_theta, variance, kx_values, ky_values, prediction=None
):
    variance = float(variance)
    if not np.isfinite(variance) or not variance > 0.0:
        raise ValueError("variance must be finite and positive")
    chi = np.asarray(chi, dtype=np.float64)
    if chi.shape != (2,) or not np.all(np.isfinite(chi)) or not np.any(chi):
        raise ValueError("chi must be a finite nonzero 2-vector")
    if not np.isfinite(delta_theta):
        raise ValueError("delta_theta must be finite")
    kx_values, ky_values = np.asarray(kx_values), np.asarray(ky_values)
    if any(a.ndim != 1 or not a.size or not np.all(np.isfinite(a))
           for a in (kx_values, ky_values)):
        raise ValueError("grid axes must be finite nonempty vectors")
    if prediction is None:
        prediction = fun_K03_predicted_phase(chi, kx_values, ky_values)
    prediction = np.asarray(prediction, dtype=np.float64)
    if prediction.shape != (ky_values.size, kx_values.size) or not np.all(np.isfinite(prediction)):
        raise ValueError("prediction must be finite and match the grid")
    residual = fun_K01_wrap_to_pi(
        np.asarray(prediction, dtype=np.float64) - float(delta_theta)
    )
    return -0.5 * residual * residual / variance
