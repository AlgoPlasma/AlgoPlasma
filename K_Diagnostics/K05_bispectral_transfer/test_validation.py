"""Known-answer and leakage tests for the complex two-probe predictor."""
import unittest
import numpy as np

from validate_experiment import (signed_pairs, design_matrix, fit_scaled,
                                 fit_fold, evaluate, normalized_correlation)


class ValidationTests(unittest.TestCase):
    def setUp(self):
        self.rng=np.random.default_rng(240)

    def complex_random(self, shape):
        return self.rng.normal(size=shape)+1j*self.rng.normal(size=shape)

    def test_signed_pairs_and_conjugates(self):
        pp=signed_pairs(6,8)
        np.testing.assert_equal(pp,[[-2,8],[-1,7],[1,5],[2,4],[3,3]])
        self.assertEqual(len(set(map(tuple,pp))),len(pp))
        c=self.complex_random((10,9));d=design_matrix(c,6,pp)
        np.testing.assert_equal(d[:,0],c[:,6])
        np.testing.assert_allclose(d[:,1],c[:,2].conj()*c[:,8])
        np.testing.assert_allclose(d[:,-1],c[:,3]**2)

    def test_known_quadratic_model_and_moments(self):
        c=self.complex_random((2000,9));d=design_matrix(c,6,signed_pairs(6,8))
        truth=np.array([1+.3j,.1-.2j,0,.2+.1j,-.1j,.05])
        y=d@truth
        q=fit_scaled(d,y);l=fit_scaled(d[:,:1],y)
        np.testing.assert_allclose(q['coef'],truth,atol=1e-13)
        np.testing.assert_allclose(d.conj().T@(y-d@q['coef']),0,atol=1e-9)
        c2=self.complex_random((700,9));d2=design_matrix(c2,6,signed_pairs(6,8))
        ev=evaluate(d2@truth,d2,l,q)
        self.assertLess(ev['nmse'][1],1e-25)
        self.assertGreater(ev['nmse'][0],.02)
        self.assertAlmostEqual(ev['budget'].sum(),ev['prediction_power'][1],places=12)
        self.assertAlmostEqual(ev['pair_cross'].sum(),ev['budget'][1],places=12)

    def test_linear_truth(self):
        c=self.complex_random((1500,9));d=design_matrix(c,6,signed_pairs(6,8))
        y=(.7-.4j)*d[:,0]
        q=fit_scaled(d,y)
        np.testing.assert_allclose(q['coef'][1:],0,atol=1e-14)
        self.assertAlmostEqual(q['coef'][0],.7-.4j)

    def test_independent_noise_does_not_create_predictive_gain(self):
        d=self.complex_random((3000,15));y=self.complex_random(3000)
        q=fit_scaled(d,y);l=fit_scaled(d[:,:1],y)
        dt=self.complex_random((20000,15));yt=self.complex_random(20000)
        ev=evaluate(yt,dt,l,q)
        self.assertGreater(ev['nmse'][0],.98)
        self.assertGreater(ev['nmse'][1],.98)
        self.assertLess(ev['improvement'],.005)

    def test_degenerate_and_zero_columns(self):
        x=self.complex_random(300);d=np.column_stack([x,2*x,np.zeros(len(x))])
        fit=fit_scaled(d,3*x)
        self.assertEqual(fit['rank'],1)
        self.assertFalse(fit['reliable'])
        self.assertTrue(np.isinf(fit['condition']))
        np.testing.assert_allclose(d@fit['coef'],3*x,atol=1e-12)
        np.testing.assert_equal(fit['coef'][-1],0)

    def test_voltage_units_restored(self):
        c=self.complex_random((600,9));pp=signed_pairs(6,8)
        d=design_matrix(c,6,pp);truth=self.complex_random(d.shape[1]);y=d@truth
        original=fit_scaled(d,y)
        scaled=fit_scaled(design_matrix(1000*c,6,pp),1000*y)
        self.assertAlmostEqual(scaled['coef'][0],original['coef'][0])
        np.testing.assert_allclose(scaled['coef'][1:]*1000,original['coef'][1:],atol=1e-12)

    def test_heldout_changes_cannot_change_training_fit(self):
        ds={g:self.complex_random((200,5)) for g in (2,3,4,5)}
        ys={g:self.complex_random(200) for g in ds}
        l,q,train=fit_fold(ds,ys,2)
        ds[2]*=1e7;ys[2][:]=1e9+1e9j
        l2,q2,train2=fit_fold(ds,ys,2)
        for a,b in ((l,l2),(q,q2)):
            for key in ('coef','scales','singular'):
                np.testing.assert_equal(a[key],b[key])
        np.testing.assert_equal(train,train2)

    def test_undefined_metrics_and_negative_improvement(self):
        d=self.complex_random((100,2));z=fit_scaled(d,np.zeros(100))
        l=fit_scaled(d[:,:1],np.zeros(100))
        ev=evaluate(np.zeros(100),d,l,z)
        self.assertTrue(np.isnan(ev['nmse']).all())
        self.assertTrue(np.isnan(ev['improvement']))
        self.assertTrue(np.isnan(normalized_correlation(np.zeros(100),d)).all())
        l['coef'][:]=1;z['coef'][:]=[1,10]
        ev=evaluate(d[:,0]+.1*self.complex_random(100),d,l,z)
        self.assertLess(ev['improvement'],0)


if __name__=='__main__':
    unittest.main()
