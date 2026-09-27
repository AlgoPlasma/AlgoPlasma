"""Twelve deterministic diagnostics checks with recorded inputs and measurements."""
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[4]))
from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_cross_phase as phase, fun_K01_pair_power as power,
    fun_K01_phase_mode_statistics as stats, fun_K01_segment_ffts as fft,
    fun_K01_power_spectrum as psd, fun_K01_wrap_to_pi as wrap,
)
from K_Diagnostics.K02_beall.fun_K02_beall_spectrum import fun_K02_beall_spectrum as beall
from K_Diagnostics.K02_beall.fun_K02_peak_wavenumber import fun_K02_peak_wavenumber as peak_k
from K_Diagnostics.K03_mle_k2d.fun_K03_search_wavevector import fun_K03_search_wavevector as search
from K_Diagnostics.K03_mle_k2d.fun_K03_joint_log_likelihood import fun_K03_joint_log_likelihood as joint


def configs(chi, truth):
    return [(c, wrap(c @ truth), 1e-6) for c in np.asarray(chi)]


from report import RecordedCase


class Regressions(RecordedCase):
    def test_liu_returns_mode_not_arithmetic_or_circular_mean(self):
        samples = np.array([0.011, 0.012, 0.013, 0.22])
        self.inputs = {'phase_rad': samples, 'bins': 60}
        mean, variance = stats(samples)
        self.arrays = {'phase_rad': samples, 'mean_rad': mean, 'variance_rad2': variance}
        self.assertAlmostEqual(mean, np.pi / 60)
        self.assertAlmostEqual(variance, np.var(wrap(samples-mean), ddof=1) + 1e-12)

    def test_branch_cut(self):
        samples = np.deg2rad([179, -179, 178, 179])
        self.inputs = {'phase_deg': [179, -179, 178, 179], 'bins': 60}
        mean, variance = stats(samples)
        self.arrays = {'phase_rad': samples, 'mean_rad': mean, 'variance_rad2': variance}
        self.assertLess(abs(wrap(mean - np.pi)), np.pi/30)
        self.assertLess(variance, 0.01)

    def test_missing_and_noiseless(self):
        self.inputs = {'shape': [4, 3], 'cases': ['zero/one FFT', 'one/one FFT', 'partly missing phases']}
        p, _ = phase(np.zeros((4, 3)), np.ones((4, 3)))
        mean, variance = stats(p)
        self.observed['zero_mean_rad'] = mean
        self.observed['zero_variance_rad2'] = variance
        self.assertTrue(np.isnan(mean).all() and np.isnan(variance).all())
        p, _ = phase(np.ones((4, 3)), np.ones((4, 3)))
        _, variance = stats(p)
        self.array_close(variance, 1e-12, rtol=0, atol=1e-25)
        mean, variance = stats(np.array([[.2, np.nan], [np.nan, np.inf], [.3, .1]]))
        self.observed['partial_mean_rad'] = mean
        self.observed['valid_counts'] = [2, 1]
        self.assertTrue(np.isfinite(mean[0]) and np.isnan(mean[1]))

    def test_beall_auto_power_changes_peak(self):
        first, second = np.array([[10.], [2.]]), np.array([[.1], [2.]])
        self.inputs = {'FFT1': first, 'FFT2': second, 'phase_rad': [-.5, .5]}
        self.array_close(power(first, second).ravel(), [50.005, 4])
        angles = np.array([[-.5], [.5]])
        result = beall(angles, power(first, second), [1.], [1., 0.], [-1, 0, 1], [.5, 1.5])
        self.assertEqual(peak_k(result['spectrum'], result['k_centers'])[0], -.5)
        old = beall(angles, np.abs(first*second), [1.], [1., 0.], [-1, 0, 1], [.5, 1.5])
        self.assertEqual(peak_k(old['spectrum'], old['k_centers'])[0], .5)
        self.arrays = {'k_rad_m': result['k_centers'], 'auto_power_spectrum': result['spectrum'][0],
                       'cross_magnitude_spectrum': old['spectrum'][0]}

    def test_no_beall_peak_without_phase(self):
        self.inputs = {'phase_rad': ['NaN'], 'power': [5.]}
        result = beall([[np.nan]], [[5.]], [1.], [1., 0.], [-1, 0, 1], [.5, 1.5])
        self.observed['spectrum'] = result['spectrum']
        self.observed['peak_rad_m'] = peak_k(result['spectrum'], result['k_centers'])
        self.assertTrue(np.isnan(peak_k(result['spectrum'], result['k_centers'])[0]))

    def test_full_grid_matches_dense_reference_for_any_block_size(self):
        cs = configs([[.005, 0], [0, .006], [.003, .004]], [80., -40.])
        self.inputs = {'chi_m': [c[0] for c in cs], 'truth_rad_m': [80, -40], 'range_rad_m': 200, 'grid_n': 41, 'block_rows': [1, 7, 100]}
        axis = np.linspace(-200, 200, 41)
        dense = joint(cs, axis, axis, normalise=False)
        iy, ix = np.unravel_index(np.argmax(dense), dense.shape)
        for rows in [1, 7, 100]:
            found = search(cs, 200, n_grid=41, block_rows=rows)
            self.assertEqual((found['kx'], found['ky']), (axis[ix], axis[iy]))
            self.assertAlmostEqual(found['peak_log_likelihood'], dense[iy, ix])

    def test_alias_requires_grid_resolution_not_local_refinement(self):
        cs = configs([[.005, 0], [.00501, 0], [0, .005], [0, .00501]], [123.4, 0])
        self.inputs = {'chi_m': [c[0] for c in cs], 'truth_rad_m': [123.4, 0], 'range_rad_m': 2000, 'grid_n': [401, 4001]}
        coarse = search(cs, 2000, n_grid=401)
        self.assertGreater(abs(coarse['kx'] - 123.4), 1000)
        resolved = search(cs, 2000, n_grid=4001)
        self.assertLess(abs(resolved['kx'] - 123.4), 1.)
        self.assertEqual(resolved['ky'], 0.)
        self.observed['estimates_rad_m'] = [[coarse['kx'], coarse['ky']], [resolved['kx'], resolved['ky']]]
        axes = [np.linspace(-2000, 2000, n) for n in [401, 4001]]
        self.arrays = {'truth_rad_m': [123.4, 0], 'estimates_rad_m': self.observed['estimates_rad_m']}
        for n, axis in zip([401, 4001], axes):
            line = joint(cs, axis, [0.], normalise=False)[0]
            self.arrays['kx_'+str(n)] = axis
            self.arrays['loglike_'+str(n)] = line

    def test_equal_length_baselines_can_resolve_alias(self):
        angles = np.deg2rad([0, 90, 45, 30])
        chi = .005 * np.column_stack((np.cos(angles), np.sin(angles)))
        self.inputs = {'chi_m': chi, 'truth_rad_m': [1200, 800], 'range_rad_m': 2000, 'grid_n': 401}
        found = search(configs(chi, [1200., 800.]), 2000, n_grid=401)
        self.assertEqual((found['kx'], found['ky']), (1200., 800.))

    def test_different_lengths_do_not_guarantee_unique_alias(self):
        chi = np.array([[.005, 0], [.010, 0], [0, .005], [0, .010]])
        delta = np.array([2*np.pi/.005, 0])
        self.inputs = {'chi_m': chi, 'wavevector_difference_rad_m': delta}
        self.array_close(wrap(chi @ delta), 0, atol=1e-12)

    def test_invalid_and_collinear_constraints(self):
        self.inputs = {'invalid_cases': ['empty', 'one baseline', 'collinear', 'NaN phase', 'infinite variance'], 'range_rad_m': 200}
        for cs in [[], [([1, 0], 0, 1)], [([1, 0], 0, 1), ([2, 0], 0, 1)],
                   [([1, 0], np.nan, 1), ([0, 1], 0, 1)],
                   [([1, 0], 0, np.inf), ([0, 1], 0, 1)]]:
            with self.assertRaises(ValueError):
                search(cs, 200, n_grid=21)
        cs = configs([[.005, 0], [0, .005]], [80., -40.])
        clean = search(cs, 200, n_grid=41)
        filtered = search(cs + [([.003, .004], np.nan, 1e-12)], 200, n_grid=41)
        self.assertEqual(clean, filtered)

    def test_leakage_can_bias_real_signal_phase(self):
        self.inputs = {'samples': 64, 'cycles': [1.25, 2.], 'phase_difference_rad': .8, 'window': 'boxcar'}
        t = np.arange(64) / 64
        errors = []
        self.arrays = {'cycles': [1.25, 2.], 'time_fraction': t}
        for cycles in [1.25, 2.]:
            x, y = np.cos(2*np.pi*cycles*t), np.cos(2*np.pi*cycles*t + .8)
            fx, fy = fft(x, 64), fft(y, 64)
            p, _ = phase(fx, fy)
            self.arrays['amplitude_'+str(cycles)] = np.abs(fx[0])
            self.arrays['signal_'+str(cycles)] = x
            errors.append(abs(wrap(p[0, round(cycles)] + .8)))
        self.arrays['error_deg'] = np.rad2deg(errors)
        self.observed['phase_error_deg'] = np.rad2deg(errors)
        self.assertGreater(errors[0], np.deg2rad(5))
        self.assertLess(errors[1], 1e-12)

    def test_window_psd_normalization(self):
        self.inputs = {'seed': 42, 'segments': 4, 'nperseg': 64, 'fs_hz': 64, 'windows': ['boxcar', 'hann']}
        samples = np.random.default_rng(42).normal(size=(4, 64))
        samples -= samples.mean(axis=1, keepdims=True)
        for window in ['boxcar', 'hann']:
            weights = np.ones(64) if window == 'boxcar' else np.hanning(64)
            spectrum = fft(samples.ravel(), 64, detrend=False, window=window)
            measured = psd(spectrum, 64., 64, window=window).sum()
            expected = np.mean(np.sum((samples*weights)**2, axis=1)) / np.sum(weights**2)
            self.observed[window] = {'PSD_integral': measured, 'time_power': expected, 'absolute_error': abs(measured-expected)}
            self.assertAlmostEqual(measured, expected)


if __name__ == '__main__':
    from report import main
    raise SystemExit(main())
