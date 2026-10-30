"""Numerical checks for the mean swept-probe workflow; no private data required."""
import unittest
import numpy as np
from analyze_probe_sweep import reduce_bins, fit_slope, floating_potential, potential_candidate


class MeanSweepTests(unittest.TestCase):
    def test_mean_point_preserves_channel_conversion(self):
        supply=np.repeat([75.2,76.4],8)
        shunt=np.array([.2]*7+[-3.8]+[.4]*8)
        points=reduce_bins(supply,shunt)
        np.testing.assert_allclose(points[:,0],[-25.1,-23.2])
        np.testing.assert_allclose(points[:,1],[.0003,-.0004])
        np.testing.assert_array_equal(points[:,4],[8,8])
        np.testing.assert_allclose(points[:,0],points[:,2]-100+points[:,3])

    def test_median_does_not_preserve_skewed_current_mean(self):
        supply=np.repeat([75.2,76.4],8)
        shunt=np.array([.2]*7+[-3.8]+[.4]*8)
        mean=reduce_bins(supply,shunt)
        median=reduce_bins(supply,shunt,statistic='median')
        self.assertAlmostEqual(median[0,1],-.0002)
        self.assertAlmostEqual(mean[0,1],.0003)

    def test_invalid_samples_or_settings_are_not_silently_removed(self):
        for args in [(np.array([1,np.nan]),np.zeros(2)),
                     (np.ones(2),np.ones(3))]:
            with self.assertRaises(ValueError):reduce_bins(*args)
        for settings in [dict(width=0),dict(resistance=-1),dict(statistic='unknown')]:
            with self.assertRaises(ValueError):reduce_bins(np.arange(20.),np.zeros(20),**settings)
        with self.assertRaises(ValueError):reduce_bins(np.ones(8),np.zeros(8))

    @staticmethod
    def characteristic():
        v=np.arange(-180.,21.)
        ion=2e-6*v-3e-4
        return v,ion+1e-3*np.exp((v+15)/9)

    def test_recovers_known_exponential_temperature(self):
        v,current=self.characteristic()
        result=fit_slope(v,current,[-180,-140],[-25,-2])
        self.assertAlmostEqual(result['te_ev'],9,delta=1e-3)
        np.testing.assert_allclose(result['ion_coeff_a'],[2e-6,-3e-4],atol=1e-8)
        self.assertGreater(result['r_squared'],.999999)

    def test_current_gain_changes_intercept_not_temperature(self):
        v,current=self.characteristic()
        a=fit_slope(v,current,[-180,-140],[-25,-2])
        b=fit_slope(v,current*1000,[-180,-140],[-25,-2])
        self.assertAlmostEqual(a['te_ev'],b['te_ev'],places=10)
        self.assertAlmostEqual(b['intercept']-a['intercept'],np.log(1000),places=10)

    def test_nonpositive_corrected_current_is_rejected(self):
        v=np.arange(-100.,21.)
        with self.assertRaises(ValueError):
            fit_slope(v,np.zeros_like(v),[-90,-50],[-20,0],ion_model='constant')
        with self.assertRaises(ValueError):
            fit_slope(v,np.zeros_like(v),[-90,-89],[-20,0])

    def test_floating_crossing_interpolates_and_rejects_ambiguity(self):
        self.assertAlmostEqual(floating_potential(np.array([-30.,-20.]),np.array([-1.,1.])), -25)
        with self.assertRaises(ValueError):
            floating_potential(np.array([-30.,-20.,-10.,0.]),np.array([-1.,1.,-1.,1.]))

    def test_smoothed_feature_of_known_transition(self):
        v=np.arange(-100.,100.,.1)
        current=.01/(1+np.exp(-(v-5)/8))-.0004
        candidate,peaks,grid,derivatives=potential_candidate(v,current,-25,[5,7,9,11,15,19,23])
        self.assertAlmostEqual(candidate,5,delta=.5)
        self.assertEqual(len(peaks),7)
        self.assertEqual(derivatives.shape,(7,len(grid)))


if __name__=='__main__':
    unittest.main()
