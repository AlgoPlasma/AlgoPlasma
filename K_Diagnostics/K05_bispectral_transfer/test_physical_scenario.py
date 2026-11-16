"""Checks for moving-ion geometry, true group velocity and display selection."""
import json
from pathlib import Path
import unittest
import numpy as np
from scipy.constants import e
from analyze_physical_scenario import (MovingColdIonEDI, frequency_map,
                                      kim_display_mask, convert_voltage_units)
from analyze_paper_comparison import ColdIonEDI


class PhysicalScenarioTests(unittest.TestCase):
    def setUp(self):
        self.cfg=json.loads(Path(__file__).with_name('physical_scenario_config.json').read_text())
        self.m=MovingColdIonEDI(self.cfg)

    def test_energy_wavelength_and_vector_drift(self):
        m=self.m
        self.assertAlmostEqual(.5*m.mi*m.ui**2/e,100.)
        self.assertAlmostEqual(m.kpar*.01,2*np.pi)
        # x cross r is the chosen positive azimuthal axis.
        E=np.array([m.ex,0.,0.]); B=np.array([m.bx,0.,-m.br])
        self.assertAlmostEqual(np.cross(E,B)[1]/np.dot(B,B),m.vd)
        self.assertAlmostEqual(m.vd,492687.927,places=1)

    def test_geometry_preserves_parallel_projection(self):
        m=self.m
        for ky in [0,1000,30000]:
            kx,kr,ks,kp=m.components(ky)
            self.assertAlmostEqual(kx*m.bhat_x+kr*m.bhat_r,kp,places=10)
            np.testing.assert_allclose(kx*kx+kr*kr+ky*ky,kp*kp+ks*ks+ky*ky)

    def test_partial_group_velocity_and_path_chain_rule(self):
        m=self.m
        for ky in [1500.,5000.,60000.]:
            kx,kr,ks,kp=m.components(ky);w,_=m.root_at(ky)
            vgy,vgs,path=m.velocities(w,ky)
            h=.1
            wp,_=m.root_at(ky+h,ks,kp,w);wm,_=m.root_at(ky-h,ks,kp,w)
            np.testing.assert_allclose(vgy,(wp.real-wm.real)/(2*h),rtol=2e-4,atol=2e-4)
            wp,_=m.root_at(ky+h,guess=w);wm,_=m.root_at(ky-h,guess=w)
            np.testing.assert_allclose(path,(wp.real-wm.real)/(2*h),rtol=2e-5)
            self.assertGreater(abs(path-vgy),1000.)

    def test_ion_advection_enters_response_not_posthoc_shift(self):
        m=self.m;ky=8000.;w,_=m.root_at(ky)
        kx,kr,ks,kp=m.components(ky);k2=(ky*ky+ks*ks+kp*kp)*m.ld**2
        electron=1+k2+m.gordeev(w,ky,ks,kp)
        np.testing.assert_allclose(electron,k2*m.wpi**2/(w-kx*m.ui)**2,rtol=1e-9)

    def test_zero_flow_and_zero_obliquity_recover_previous_response(self):
        m=MovingColdIonEDI(dict(self.cfg,perpendicular_obliquity_deg=0))
        m.ui=0.
        old=ColdIonEDI(dict(self.cfg,k_parallel_debye=m.kpar*m.ld,
                            electron_drift_m_per_s=m.vd))
        for ky,w in [(1500.,1e7+2e5j),(7000.,2e7+1e6j)]:
            np.testing.assert_allclose(m.dielectric(w,ky),old.dielectric(w,ky),rtol=1e-12)

    def test_no_extrapolation_and_no_cherry_picked_folds(self):
        b=dict(omega=np.array([10,20])*2*np.pi+1j,vg=np.array([2,3]),
               ky=np.array([1,2]),path_slope=np.array([4,5]))
        self.assertTrue(np.isnan(frequency_map(b,[5,30])['vg']).all())
        admissible=np.ones((4,3),bool);admissible[1,1]=False
        identified=np.ones_like(admissible);identified[3,2]=False
        np.testing.assert_array_equal(kim_display_mask(admissible,identified),[True,False,False])

    def test_current_conversion_preserves_predictions_and_rates(self):
        c=np.array([.9+.2j,2-1j]);power=np.array([.8]);T=np.array([-.3])
        a=.001; cc,pp,tt=convert_voltage_units(c,power,T,a)
        x=.2+.5j;z=.1+.3j
        np.testing.assert_allclose(cc[0]*(a*x)+cc[1]*(a*a*z),a*(c[0]*x+c[1]*z))
        np.testing.assert_allclose(tt/pp,T/power)
        self.assertEqual(cc[0],c[0])


if __name__=='__main__':
    unittest.main()
