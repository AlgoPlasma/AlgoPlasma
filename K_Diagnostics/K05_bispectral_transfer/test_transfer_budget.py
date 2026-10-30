"""Deterministic checks of moments, scaling and the complete power identities."""
import unittest
import numpy as np
from analyze_transfer_budget import fit_kim, power_budget


class KimTests(unittest.TestCase):
    def setUp(self):
        t=np.arange(512)*2*np.pi/512
        self.x=np.exp(1j*t)
        self.z=np.exp(3j*t)[:,None]  # product of harmonics 1 and 2
        self.noise=np.exp(7j*t)

    def test_known_stationary_quadratic(self):
        l=.8*np.exp(.4j);q=.6*np.exp(-.3j)
        d=np.column_stack([self.x,self.z])
        f=fit_kim(d,l*self.x+q*self.z[:,0])
        np.testing.assert_allclose(f['coef'],[l,q],atol=2e-14)
        self.assertAlmostEqual(f['pstar'],1)
        self.assertTrue(f['admissible'])
        self.assertLess(f['moment_error'],1e-13)

    def test_input_and_output_independent_nonideal_power(self):
        # Harmonics make all relevant cross moments vanish exactly.
        x=self.x+.5*self.noise
        y=np.exp(.7j)*self.x+.4*np.exp(11j*np.arange(512)*2*np.pi/512)
        f=fit_kim(np.column_stack([x,self.z]),y)
        self.assertAlmostEqual(f['pstar'],1)
        np.testing.assert_allclose(f['coef'],[np.exp(.7j),0],atol=2e-14)
        self.assertTrue(f['admissible'])

    def test_complex_correlated_product_moments(self):
        # Nonzero complex <X Z*> audits conjugations beyond orthogonal examples.
        rho=.25j
        x=self.x+rho*self.z[:,0]
        linear=.8+.1j
        c2=np.sqrt(1+abs(rho)**2-abs(linear)**2)*np.exp(.6j)
        q=c2-linear*rho
        y=linear*x+q*self.z[:,0]
        fit=fit_kim(np.column_stack([x,self.z]),y)
        np.testing.assert_allclose(fit['coef'],[linear,q],atol=1e-13)
        self.assertAlmostEqual(fit['pstar'],1+abs(rho)**2)
        self.assertTrue(fit['admissible'])

    def test_zero_cross_power_not_identifiable(self):
        f=fit_kim(self.x[:,None],self.noise)
        self.assertFalse(f['identified'])

    def test_growing_linear_signal_violates_stationarity_bound(self):
        f=fit_kim(self.x[:,None],2*self.x)
        self.assertTrue(f['identified'])
        self.assertFalse(f['admissible'])
        self.assertAlmostEqual(f['pstar'],2)
        self.assertAlmostEqual(abs(f['coef'][0]),1)

    def test_collinear_products_rejected(self):
        d=np.column_stack([self.x,self.z,self.z])
        self.assertFalse(fit_kim(d,self.x)['identified'])

    def test_input_voltage_units_and_output_phase(self):
        d=np.column_stack([self.x,self.z]);y=.8*self.x+.6*self.z[:,0]
        f=fit_kim(d,y)
        # Both voltage channels times c => X*c, Z*c^2, Y*c; L same, Q/c.
        c=1e-3
        changed=fit_kim(d*np.array([c,c*c]),y*c)
        np.testing.assert_allclose(changed['coef']*np.array([1,c]),f['coef'],atol=1e-12)
        self.assertAlmostEqual(changed['pstar']/c**2,f['pstar'])
        rotated=fit_kim(d,y*np.exp(.9j))
        np.testing.assert_allclose(rotated['coef'],f['coef']*np.exp(.9j),atol=1e-13)

    def test_budget_keeps_residual_cross_and_quadratic_square(self):
        rng=np.random.default_rng(81)
        d=rng.normal(size=(400,4))+1j*rng.normal(size=(400,4))
        coef=np.array([.8+.1j,.1,.2j,-.12])
        y=d@coef+.3*d[:,0]+rng.normal(size=400)
        b,inc=power_budget(d,y,coef,.6)
        self.assertAlmostEqual(b.sum(),1)
        ratio=np.mean(abs(y)**2)/np.mean(abs(d[:,0])**2)
        self.assertAlmostEqual(inc.sum(),ratio-1)
        self.assertGreater(abs(b[-1]),.01)
        self.assertGreater(b[2],0)

    def test_heldout_values_cannot_change_fit(self):
        d=np.column_stack([self.x,self.z]);y=.8*self.x+.6*self.z[:,0]
        before=fit_kim(d,y)
        for changed in [self.noise,100*self.noise]:
            power_budget(d,changed,before['coef'],0)
        after=fit_kim(d,y)
        np.testing.assert_array_equal(before['coef'],after['coef'])
        np.testing.assert_array_equal(before['scales'],after['scales'])


if __name__=='__main__':
    unittest.main()
