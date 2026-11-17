"""Independent checks for the new physical conversion and kinetic scenario."""
import json
from pathlib import Path
import unittest

import numpy as np
from scipy.integrate import quad

from analyze_paper_comparison import ColdIonEDI, convert_rates, map_frequency, symmetric_q_map


class ComparisonTests(unittest.TestCase):
    def setUp(self):
        self.config = json.loads(Path(__file__).with_name("paper_comparison_config.json").read_text(encoding="utf-8"))
        self.model = ColdIonEDI(self.config)

    def test_gordeev_matches_independent_orbit_integral(self):
        m = self.model
        for k, omega in [(4000., 1.1e7+2e5j), (15000., 2.5e7+5e5j)]:
            om = (omega-k*m.vd)/m.wce
            x, y = (k*m.vte/m.wce)**2, (m.kpar*m.vte/m.wce)**2
            def integrand(t):
                return 1j*om*np.exp(-x*(1-np.cos(t))-.5*y*t*t+1j*om*t)
            # Split the orbit integral so adaptive quadrature cannot skip narrow
            # cyclotron-period peaks. Gaussian envelope beyond tmax is < exp(-40).
            tmax=np.sqrt(80/y)
            edges=np.r_[np.arange(0,tmax,np.pi),tmax]
            real=sum(quad(lambda t: integrand(t).real, lo, hi, epsabs=1e-12)[0]
                     for lo,hi in zip(edges[:-1],edges[1:]))
            imag=sum(quad(lambda t: integrand(t).imag, lo, hi, epsabs=1e-12)[0]
                     for lo,hi in zip(edges[:-1],edges[1:]))
            np.testing.assert_allclose(m.gordeev(omega,k)[0], real+1j*imag, rtol=1e-9, atol=1e-10)

    def test_without_electron_drift_the_selected_branch_is_damped(self):
        cfg = dict(self.config, electron_drift_m_per_s=0.)
        model = ColdIonEDI(cfg)
        for k in [1500., 5000., 20000.]:
            omega, err = model.root_at(k)
            self.assertLess(omega.imag, 0.)
            self.assertLess(err, 1e-9)

    def test_group_velocity_agrees_with_independently_resolved_roots(self):
        m = self.model
        for k in [1500., 7000., 20000.]:
            omega, _ = m.root_at(k)
            plus, _ = m.root_at(k+.1, omega)
            minus, _ = m.root_at(k-.1, omega)
            finite = (plus.real-minus.real)/.2
            np.testing.assert_allclose(m.group_velocity(omega,k), finite, rtol=2e-6)

    def test_no_extrapolation_or_multivalued_frequency_mapping(self):
        branch = dict(ky=np.array([1,2]), omega=2*np.pi*np.array([10+1j,20+2j]), vg=np.array([3,4]))
        vg, gamma, ky = map_frequency(branch, [5,15,30])
        self.assertTrue(np.isnan(vg[[0,2]]).all())
        self.assertEqual(vg[1],3.5)
        branch["omega"] = branch["omega"][::-1]
        with self.assertRaises(ValueError):
            map_frequency(branch,[15])

    def test_ordered_pair_map_preserves_sum_and_real_signal_symmetry(self):
        pairs=np.array([[[-1,3],[1,1]]]); count=np.array([2])
        unique=np.array([[2+3j,-.2+.5j]])
        bins,q=symmetric_q_map(pairs,count,unique)
        center=len(bins)//2
        coeff={1:1+.5j,3:-.2+.1j}
        coeff[-1]=coeff[1].conjugate()
        unordered=sum(unique[0,j]*coeff[b]*coeff[c] for j,(b,c) in enumerate(pairs[0]))
        ordered=sum(q[b+center,c+center]*coeff[b]*coeff[c] for b,c in [(-1,3),(3,-1),(1,1)])
        np.testing.assert_allclose(ordered,unordered)
        np.testing.assert_allclose(q, q[::-1,::-1].conj(), equal_nan=True)
        self.assertTrue(np.isnan(q[center,center]))
        # A common voltage-unit change divides Q by that scale.
        _,q2=symmetric_q_map(pairs,count,unique/1000)
        np.testing.assert_allclose(q2,q/1000,equal_nan=True)

    def test_half_power_factor_units_and_phase(self):
        phase=np.array([.4]); linear=1.1*np.exp(1j*phase)
        gamma,t=convert_rates(linear,phase,np.array([.2]),np.array([4.]),np.array([20.]),.01)
        np.testing.assert_allclose(gamma,[200.])
        np.testing.assert_allclose(t,[800.])
        same_gamma,scaled_t=convert_rates(linear,phase,np.array([.2]),np.array([4e6]),np.array([20.]),.01)
        np.testing.assert_allclose(same_gamma,gamma)
        np.testing.assert_allclose(scaled_t,t*1e6)
        reversed_g,reversed_t=convert_rates(linear,phase,np.array([.2]),np.array([4.]),np.array([-20.]),.01)
        np.testing.assert_allclose(reversed_g,-gamma)
        np.testing.assert_allclose(reversed_t,-t)


if __name__ == "__main__":
    unittest.main()
