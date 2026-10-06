"""Deterministic diagnostics checks with recorded inputs and measurements."""
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[4]))
from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_cross_phase as phase, fun_K01_pair_power as power,
    fun_K01_phase_mode_statistics as stats, fun_K01_segment_ffts as fft,
    fun_K01_power_spectrum as psd, fun_K01_wrap_to_pi as wrap,
    fun_K01_coherence as coherence,
)
from K_Diagnostics.K02_beall.fun_K02_beall_spectrum import fun_K02_beall_spectrum as beall
from K_Diagnostics.K02_beall.fun_K02_peak_wavenumber import fun_K02_peak_wavenumber as peak_k
from K_Diagnostics.K03_mle_k2d.fun_K03_search_wavevector import fun_K03_search_wavevector as search
from K_Diagnostics.K03_mle_k2d.fun_K03_joint_log_likelihood import fun_K03_joint_log_likelihood as joint
from K_Diagnostics.K02_beall.fun_K02_separation_magnitude import fun_K02_separation_magnitude as distance


def configs(chi, truth):
    return [(c, wrap(c @ truth), 1e-6) for c in np.asarray(chi)]


from report import RecordedCase

# Explicit float64 regression budgets, not physical accuracy requirements.
# 64 eps allows for short arithmetic chains and different evaluation orders;
# 64*N eps additionally allows for 64-term reductions / direct DFT sums.
# These conservative engineering margins are not rigorous forward-error bounds.
EPS = np.finfo(np.float64).eps
SHORT_RTOL = 64 * EPS
SUM_RTOL = 64 * 64 * EPS
ANGLE_ATOL = SHORT_RTOL * (2 * np.pi)
VARIANCE_ATOL = SHORT_RTOL * (2 * np.pi)**2
DFT_ANGLE_ATOL = SUM_RTOL * (2 * np.pi)


class Regressions(RecordedCase):
    def test_variance_weights_resolve_conflicting_observations(self):
        # No wrapping in [-1,1]^2. Minimise x^2 + (x-1)^2/9 + y^2:
        # derivative 2*x + 2*(x-1)/9 = 0 gives x=0.1, y=0.
        cs = [([1, 0], 0., 1.), ([1, 0], 1., 9.), ([0, 1], 0., 1.)]
        self.inputs = {'configurations': cs, 'range_rad_m': 1, 'grid_n': 21}
        found = search(cs, 1, n_grid=21)
        self.array_close([found['kx'], found['ky']], [.1, 0], rtol=0, atol=SHORT_RTOL)
        self.array_close(found['peak_log_likelihood'], -.05, rtol=SHORT_RTOL, atol=0)
        axis = np.linspace(-1, 1, 21)
        dense = joint(cs, axis, axis, normalise=False)
        # Check the score independently too; both implementations could share a bug.
        self.array_close(dense[10, 11], -.05, rtol=SHORT_RTOL, atol=0)
        equal = search([(c, t, 1.) for c, t, v in cs], 1, n_grid=21)
        self.array_close([equal['kx'], equal['ky']], [.5, 0], rtol=0, atol=SHORT_RTOL)

    def test_psd_units_and_endpoint_scaling(self):
        self.inputs = {'lengths': [63, 64], 'sampling_rates_hz': [1000, 2000], 'detrend': False}
        for n in [63, 64]:
            j = np.arange(n)
            # Highest rFFT bin: paired +/- frequencies for odd n, Nyquist for even n.
            signal = 2. + np.cos(2*np.pi*(n//2)*j/n)
            ffts = fft(signal, n, detrend=False)
            for fs in [1000., 2000.]:
                density = psd(ffts, fs, n)
                expected_ac = 1. if n % 2 == 0 else .5
                self.array_close(density[[0, -1]] * fs/n, [4., expected_ac], rtol=SUM_RTOL, atol=0)
                self.array_close(density.sum()*fs/n, 4.+expected_ac, rtol=SUM_RTOL, atol=0)

    def test_coherence_known_complex_pairs(self):
        first = np.ones((4, 2), dtype=complex)
        second = np.column_stack([np.full(4, 2j), [1, -1, 1, -1]])
        self.inputs = {'first': 'ones (4,2)', 'second': 'constant 2j; cancelling signs'}
        self.array_close(coherence(first, second), [1., 0.], rtol=SHORT_RTOL, atol=SHORT_RTOL)
        self.array_close(coherence(first*3, second*5), [1., 0.], rtol=SHORT_RTOL, atol=SHORT_RTOL)

    def test_reject_invalid_beall_baselines(self):
        self.inputs = {'baselines': [[0, 0], [float('nan'), 0], [float('inf'), 0]]}
        for chi in self.inputs['baselines']:
            with self.assertRaises(ValueError):
                distance(chi)
            with self.assertRaises(ValueError):
                beall([[0.]], [[1.]], [1.], chi, [-1, 0, 1], [.5, 1.5])

    def test_liu_returns_mode_not_arithmetic_or_circular_mean(self):
        samples = np.array([0.011, 0.012, 0.013, 0.22])
        self.inputs = {'phase_rad': samples, 'bins': 60}
        mean, variance = stats(samples)
        self.arrays = {'phase_rad': samples, 'mean_rad': mean, 'variance_rad2': variance}
        self.array_close(mean, np.pi / 60, rtol=0, atol=ANGLE_ATOL)
        # All samples fit on one branch. Hand-derived deviations from 0.064:
        expected_variance = ((-.053)**2 + (-.052)**2 + (-.051)**2 + .156**2) / 3 + 1e-12
        self.array_close(variance, expected_variance, rtol=SHORT_RTOL, atol=VARIANCE_ATOL)

    def test_branch_cut(self):
        samples = np.deg2rad([179, -179, 178, 179])
        self.inputs = {'phase_deg': [179, -179, 178, 179], 'bins': 60}
        mean, variance = stats(samples)
        self.arrays = {'phase_rad': samples, 'mean_rad': mean, 'variance_rad2': variance}
        # Unwrap by inspection: [179, 181, 178, 179] degrees, mean 179.25.
        # The most populated histogram bin is [174, 180), centered at 177.
        expected_variance = (19 / 12) * (np.pi / 180)**2 + 1e-12
        self.array_close(mean, 177 * np.pi / 180, rtol=0, atol=ANGLE_ATOL)
        self.array_close(variance, expected_variance, rtol=SHORT_RTOL, atol=VARIANCE_ATOL)

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
        self.array_close(power(first, second).ravel(), [50.005, 4], rtol=SHORT_RTOL, atol=0)
        angles = np.array([[-.5], [.5]])
        result = beall(angles, power(first, second), [1.], [1., 0.], [-1, 0, 1], [.5, 1.5])
        self.assertEqual(peak_k(result['spectrum'], result['k_centers'])[0], -.5)
        old = beall(angles, np.abs(first*second), [1.], [1., 0.], [-1, 0, 1], [.5, 1.5])
        self.assertEqual(peak_k(old['spectrum'], old['k_centers'])[0], .5)
        self.arrays = {'k_rad_m': result['k_centers'], 'auto_power_spectrum': result['spectrum'][0],
                       'cross_magnitude_spectrum': old['spectrum'][0]}
        # Each occupied bin contains one weight divided by two segments.
        self.array_close(result['spectrum'][0], [25.0025, 2], rtol=SHORT_RTOL, atol=0)
        self.array_close(old['spectrum'][0], [.5, 2], rtol=SHORT_RTOL, atol=0)

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
        self.array_close(wrap(chi @ delta), 0, rtol=0, atol=SHORT_RTOL * (4 * np.pi))

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
        measured_phases, reference_phases = [], []
        self.arrays = {'cycles': [1.25, 2.], 'time_fraction': t}
        for cycles in [1.25, 2.]:
            x, y = np.cos(2*np.pi*cycles*t), np.cos(2*np.pi*cycles*t + .8)
            fx, fy = fft(x, 64), fft(y, 64)
            p, _ = phase(fx, fy)
            self.arrays['amplitude_'+str(cycles)] = np.abs(fx[0])
            self.arrays['signal_'+str(cycles)] = x
            errors.append(abs(wrap(p[0, round(cycles)] + .8)))
            # Independent direct sum, without the FFT or cross-phase routines.
            kernel = np.exp(-2j * np.pi * round(cycles) * t)
            dx = np.sum((x - x.mean()) * kernel)
            dy = np.sum((y - y.mean()) * kernel)
            cross = dx * dy.conjugate()
            measured_phases.append(float(p[0, round(cycles)]))
            reference_phases.append(float(np.arctan2(cross.imag, cross.real)))
        self.arrays['error_deg'] = np.rad2deg(errors)
        self.observed['phase_error_deg'] = np.rad2deg(errors)
        self.observed['reference_phase_rad'] = reference_phases
        self.observed['measured_phase_rad'] = measured_phases
        # These references lie well inside (-pi, pi); ordinary differences suffice.
        self.array_close(measured_phases[0], reference_phases[0], rtol=0, atol=DFT_ANGLE_ATOL)
        self.array_close(measured_phases[1], reference_phases[1], rtol=0, atol=DFT_ANGLE_ATOL)
        self.array_close(measured_phases[1], -.8, rtol=0, atol=DFT_ANGLE_ATOL)

    def test_window_psd_normalization(self):
        self.inputs = {'seed': 42, 'segments': 4, 'nperseg': 64, 'fs_hz': 64, 'windows': ['boxcar', 'hann']}
        samples = np.random.default_rng(42).normal(size=(4, 64))
        samples -= samples.mean(axis=1, keepdims=True)
        for window in ['boxcar', 'hann']:
            weights = np.ones(64) if window == 'boxcar' else np.hanning(64)
            spectrum = fft(samples.ravel(), 64, detrend=False, window=window)
            df = 64. / 64
            measured = psd(spectrum, 64., 64, window=window).sum() * df
            expected = np.mean(np.sum((samples*weights)**2, axis=1)) / np.sum(weights**2)
            self.observed[window] = {'PSD_integral': measured, 'time_power': expected, 'absolute_error': abs(measured-expected)}
            self.array_close(measured, expected, rtol=SUM_RTOL, atol=0)


if __name__ == '__main__':
    from report import main
    raise SystemExit(main())
