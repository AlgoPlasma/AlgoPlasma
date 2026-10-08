"""Small deterministic counterexamples for the broadband acceptance logic."""
import unittest

import numpy as np

from analyze import config, evaluate_wavevectors, threshold_crossing


class AcceptanceChecks(unittest.TestCase):
    def setUp(self):
        self.frequencies = config.mode_frequencies()[::config.MODE_STRIDE]
        self.truth = config.mode_wavevectors()[::config.MODE_STRIDE]
        self.peaks = [dict(boundary=False, tied_grid_points=1) for _ in self.frequencies]
        self.step = 2*config.wavenumber_range()/(config.N_GRID-1)

    def evaluate(self, recovered):
        return evaluate_wavevectors(self.frequencies, recovered, self.truth, self.peaks, self.step)

    def test_exact_truth_passes(self):
        self.assertTrue(self.evaluate(self.truth)['passed'])

    def test_one_bad_low_frequency_fails_despite_good_slope(self):
        recovered = self.truth.copy()
        recovered[0] *= 2
        result = self.evaluate(recovered)
        self.assertLess(result['sound_speed_relative_error'], config.ACCEPTANCE['sound_speed_relative_error'])
        self.assertEqual(result['bad_modes'], 1)
        self.assertFalse(result['passed'])
        self.assertIn('vector_error_exceeds_budget', result['modes'][0]['reasons'])

    def test_boundary_and_tied_peaks_are_recorded_and_fail(self):
        for flag, value, reason in [('boundary', True, 'boundary_peak'),
                                    ('tied_grid_points', 2, 'tied_grid_maxima')]:
            with self.subTest(flag=flag):
                self.peaks[0] = dict(boundary=False, tied_grid_points=1)
                self.peaks[0][flag] = value
                result = self.evaluate(self.truth)
                self.assertFalse(result['passed'])
                self.assertIn(reason, result['modes'][0]['reasons'])

    def test_threshold_uses_total_power(self):
        # Signal=9 and noise=1 means total=10, exactly at the first frequency.
        self.assertAlmostEqual(threshold_crossing(100., 9., 1.), 100.)


if __name__ == '__main__':
    unittest.main()
