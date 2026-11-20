# K05 contribution history (Git author dates; edit times include timezone).
# 2026-11-13 13:10 +08:00 | Yinjian Zhao | git dfd0f9af0503
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Check compressed fits against full training rows, including degeneracy."""
import unittest
import numpy as np
from analyze_extended_comparison import compressed_fit
from analyze_transfer_budget import fit_kim, power_budget
from validate_experiment import fit_scaled, design_matrix, signed_pairs


class CompressedFits(unittest.TestCase):
    def test_preserves_models_and_noise_power(self):
        rng=np.random.default_rng(20261113)
        c=(rng.normal(size=(700,14))+1j*rng.normal(size=(700,14)))*.02
        d=design_matrix(c,7,signed_pairs(7,13))
        coef=(rng.normal(size=d.shape[1])+1j*rng.normal(size=d.shape[1]))
        for quadratic,noise in [(0,0), (1,0), (1,.03), (0,.2)]:
            y=coef[0]*d[:,0]+quadratic*d[:,1:]@coef[1:]
            y=y+noise*(rng.normal(size=len(d))+1j*rng.normal(size=len(d)))
            ls,km=compressed_fit(d,y)
            direct_ls, direct_km=fit_scaled(d,y),fit_kim(d,y)
            for key in ('coef','scales','singular','condition'):
                np.testing.assert_allclose(ls[key],direct_ls[key],rtol=2e-10,atol=1e-11)
            for key in ('coef','scales','px','py','pstar','alpha','beta','eta','g','condition'):
                np.testing.assert_allclose(km[key],direct_km[key],rtol=2e-10,atol=1e-11)
            self.assertEqual(km['admissible'],direct_km['admissible'])
            # A complete finite-step balance holds also on independent rows.
            dt=design_matrix(c[:101]*1.3,7,signed_pairs(7,13))
            yt=y[:101]*.7
            parts,inc=power_budget(dt,yt,ls['coef'],np.angle(km['g']))
            self.assertAlmostEqual(parts.sum(),1,places=12)
            self.assertAlmostEqual(inc.sum(),np.mean(abs(yt)**2)/np.mean(abs(dt[:,0])**2)-1,places=12)

    def test_degenerate_product_is_flagged(self):
        rng=np.random.default_rng(9)
        x=rng.normal(size=120)+1j*rng.normal(size=120)
        d=np.column_stack((x,x*x,x*x))
        ls,km=compressed_fit(d,.7*x+.2*x*x)
        self.assertFalse(ls['reliable'])
        self.assertFalse(km['identified'])
        self.assertFalse(km['admissible'])

    def test_independent_target_retains_power(self):
        rng=np.random.default_rng(8)
        d=rng.normal(size=(1000,11))+1j*rng.normal(size=(1000,11))
        y=rng.normal(size=1000)+1j*rng.normal(size=1000)
        _,km=compressed_fit(d,y)
        self.assertAlmostEqual(km['py'],np.mean(abs(y)**2),places=12)

    def test_holdout_values_do_not_enter_training(self):
        rng=np.random.default_rng(10)
        d=rng.normal(size=(400,12))+1j*rng.normal(size=(400,12))
        y=rng.normal(size=400)+1j*rng.normal(size=400)
        a=compressed_fit(d[:300],y[:300])
        d[300:]*=100; y[300:]+=100j
        b=compressed_fit(d[:300],y[:300])
        for left,right in zip(a,b):
            np.testing.assert_array_equal(left['coef'],right['coef'])
            np.testing.assert_array_equal(left['scales'],right['scales'])


if __name__=='__main__':
    unittest.main()
