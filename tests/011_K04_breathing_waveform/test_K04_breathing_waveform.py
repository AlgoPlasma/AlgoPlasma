"""Deterministic numerical checks for K04; run with unittest from repo root."""
import contextlib
import io
from pathlib import Path
import textwrap
import unittest
import sys

sys.dont_write_bytecode = True
CASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(CASE_DIR/'source_py'))
from _paths import REPO_ROOT
import numpy as np
from K_Diagnostics.K04_breathing_waveform.mod_K04_breathing_waveform import (
    fun_K04_find_frequency as frequency,
    fun_K04_make_complex_signal as complex_signal,
    fun_K04_mark_position as phase,
    fun_K04_put_into_bins as bins,
    fun_K04_mean_other_records as mean,
    fun_K04_mean_to_coefficients as coefficients,
    fun_K04_coefficients_to_grid as grid,
    fun_K04_grid_to_time as replay,
    fun_K04_extract_waveform as extract,
    fun_K04_compact_phase as compact,
)
from run_example import run_example
from run_compact_phase import run_example as run_compact


def python_blocks(path):
    """Read actual language-scoped teaching snippets to prevent module/page drift."""
    result=[]
    for part in path.read_text(encoding='utf-8').split('.. container:: ap-lang ap-lang-')[1:]:
        lines=part.splitlines(); blocks=[]; i=0
        while i<len(lines):
            if lines[i].strip()!='.. code-block:: python':
                i+=1; continue
            indent=len(lines[i])-len(lines[i].lstrip()); i+=1; body=[]
            while i<len(lines) and (not lines[i].strip() or len(lines[i])-len(lines[i].lstrip())>indent):
                body.append(lines[i]); i+=1
            blocks.append(textwrap.dedent('\n'.join(body)).strip())
        result.append(blocks)
    return result


class KnownSignalTests(unittest.TestCase):
    def test_positive_frequency_half_amplitude_and_known_phase(self):
        fs=2e6; t=np.arange(40000)/fs
        known=2*np.pi*40000*t+.63+.1*np.sin(2*np.pi*250*t)
        F,f,f0=frequency(3+2*np.cos(known),fs)
        self.assertEqual(f0,40000)
        mask,z=complex_signal(F,f)
        selected=(f>=25e3)&(f<=55e3)
        np.testing.assert_array_equal(mask[selected],F[selected])
        self.assertEqual(np.count_nonzero(mask[~selected]),0)
        np.testing.assert_allclose(abs(z),1,atol=1e-10)
        phi,theta=phase(z)
        np.testing.assert_allclose(np.angle(np.exp(1j*(phi-known))),0,atol=1e-10)
        self.assertTrue(np.all((theta>=0)&(theta<2*np.pi)))

    def test_bins_use_original_voltage_and_wrap_phase(self):
        S,K=bins([1,2,3,4],[0,2*np.pi,-2*np.pi,np.pi],4)
        np.testing.assert_array_equal(S,[6,0,4,0])
        np.testing.assert_array_equal(K,[3,0,1,0])

    def test_sample_weighting_and_held_out_exclusion(self):
        S=np.array([[999.]*4,[4.]*4,[18.]*4]); K=np.array([[3]*4,[2]*4,[6]*4])
        mu,count=mean(S,K,0)
        np.testing.assert_allclose(mu,2.75)
        np.testing.assert_array_equal(count,[8]*4)
        S[0]*=-1e9; K[0]*=1000
        np.testing.assert_array_equal(mean(S,K,0)[0],mu)

    def test_bin_centers_cutoff_and_constant(self):
        beta=2*np.pi*(np.arange(256)+.5)/256
        mu=.4+1.7*np.cos(beta+.3)+.2*np.sin(75*beta)+.1*np.cos(76*beta)
        g,w,H=grid(coefficients(mu),39510,8e6)
        self.assertEqual(H,75)
        np.testing.assert_allclose(w,.4+1.7*np.cos(g+.3)+.2*np.sin(75*g),atol=1e-12)
        _,dc,H0=grid(coefficients(mu),40000,8e6,cutoff=20000)
        self.assertEqual(H0,0)
        np.testing.assert_allclose(dc,.4,atol=1e-12)

    def test_periodic_lookup_including_last_interval(self):
        g=2*np.pi*np.arange(8)/8; w=np.cos(g)
        at=[0,2*np.pi,-2*np.pi,2*np.pi-np.pi/8]
        np.testing.assert_allclose(replay(at,g,w),[1,1,1,.5*(w[-1]+w[0])],atol=1e-14)

    def test_repeatable_high_order_survives_averaging_random_signs_do_not(self):
        beta=2*np.pi*(np.arange(256)+.5)/256
        shape=np.cos(beta)+.2*np.cos(20*beta)
        noise=np.random.default_rng(6).normal(size=256)
        mu,_=mean([shape+4*noise,shape+noise,shape-noise],np.ones((3,256)),0)
        g,high,_=grid(coefficients(mu),40000,8e6,cutoff=1e6)
        _,low,_=grid(coefficients(mu),40000,8e6,cutoff=.5e6)
        np.testing.assert_allclose(high,np.cos(g)+.2*np.cos(20*g),atol=1e-12)
        np.testing.assert_allclose(low,np.cos(g),atol=1e-12)

    def test_invalid_inputs_raise(self):
        calls=[lambda:frequency([1,np.nan],8e6),lambda:frequency([1,2],np.nan),
               lambda:frequency(np.ones(8,dtype=complex),8e6),
               lambda:complex_signal(np.ones(8),np.arange(7)),
               lambda:phase([0,1j]),lambda:bins([1],[0],B=3.5),
               lambda:bins([1],[np.inf]),lambda:mean(np.ones((3,4)),np.zeros((3,4)),0),
               lambda:mean(np.ones((3,4)),-np.ones((3,4)),0),
               lambda:coefficients(np.ones(5)),
               lambda:grid(np.ones(129),40000,8e6,cutoff=1e10),
               lambda:grid(np.ones(17),40000,8e6),
               lambda:grid(np.ones(129),40000,8e6,M=100),
               lambda:replay([0],[.1,.2],[1,2]),
               lambda:extract([np.ones(8)]*2,8e6),
               lambda:compact(np.ones(8),8e6,oversample=0)]
        for call in calls:
            with self.subTest(call=call), self.assertRaises(ValueError): call()


class WorkedExampleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data,cls.metrics=run_example()

    def test_recovery_and_reconstruction_identity(self):
        d=self.data
        self.assertEqual(self.metrics['f0_hz'],39750)
        self.assertEqual(self.metrics['H'],75)
        self.assertGreater(self.metrics['min_training_count'],5000)
        # A 10 mV regression budget for this fixed synthetic case, not measured-data accuracy.
        self.assertLess(self.metrics['rmse_v'],.01)
        np.testing.assert_allclose(d['C']+d['R'],d['xs'][0],rtol=0,atol=2e-15)
        self.assertGreater(d['res_rms'][32],2*d['res_rms'][160])

    def test_actual_page_snippets_match_module(self):
        root=REPO_ROOT
        blocks=python_blocks(root/'docs/source/rst_files/K_Diagnostics/K04_breathing_waveform.rst')
        self.assertEqual(len(blocks),2); self.assertEqual(blocks[0],blocks[1])
        self.assertEqual(len(blocks[0]),12)
        ns={}; generate=next(b for b in blocks[0] if 'def synthetic_data(' in b)
        with contextlib.redirect_stdout(io.StringIO()):
            exec(generate,ns)
            for block in blocks[0]:
                if block!=generate: exec(block,ns)
        for key in ('C','R','mu','a','gamma','w','K_train','res_mean','res_rms'):
            np.testing.assert_allclose(self.data[key],ns[key],rtol=1e-12,atol=1e-13,err_msg=key)

    def test_record_lengths_may_differ(self):
        fs=2e6; records=[]
        for N,offset in [(8000,.1),(10000,.4),(12000,-.6)]:
            t=np.arange(N)/fs
            records.append(.6+1.8*np.cos(2*np.pi*40000*t+offset))
        d=extract(records,fs,bins=16,cutoff=80000,grid_size=128)
        self.assertEqual(d['C'].shape,records[0].shape)
        self.assertEqual([len(p) for p in d['positions']],[8000,10000,12000])
        np.testing.assert_allclose(d['C']+d['R'],records[0],atol=1e-14)


class CompactPhaseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.data,cls.metrics=run_compact()

    def test_shift_normalization_and_known_phase(self):
        d=self.data; indices=np.array([0,1,37,1000,4095]); tt=d['tau'][indices]
        direct=(d['F'][d['band']][:,None]*np.exp(2j*np.pi*d['f'][d['band']][:,None]*tt)).sum(axis=0)/d['N']
        np.testing.assert_allclose(d['v'][indices],direct*np.exp(-2j*np.pi*d['fL']*tt),atol=2e-10)
        np.testing.assert_allclose(d['q'][indices],direct*np.exp(-2j*np.pi*d['f0']*tt),atol=2e-10)
        np.testing.assert_allclose(abs(d['q']),.9,atol=2e-10)
        np.testing.assert_allclose(np.angle(np.exp(1j*(d['phi_direct']-d['phi_known']))),0,atol=2e-10)
        self.assertEqual(d['L'],601); self.assertEqual(d['M_base'],4096)
        self.assertLess(self.metrics['phase_rmse_rad'],1e-6)
        self.assertLess(self.metrics['phase_max_error_rad'],2e-6)

    def test_actual_knowledge_note_snippets(self):
        root=REPO_ROOT
        blocks=python_blocks(root/'docs/source/knowledge/compact_phase.rst')
        self.assertEqual(blocks[0],blocks[1]); self.assertEqual(len(blocks[0]),7)
        ns={}
        with contextlib.redirect_stdout(io.StringIO()):
            for block in blocks[0]: exec(block,ns)
        np.testing.assert_allclose(self.data['phi_compact'],ns['phi_compact'],rtol=0,atol=1e-12)

    def test_more_coarse_points_reduce_interpolation_error(self):
        d=self.data; coarse=compact(d['x'],d['fs'],oversample=2)['phi_compact']
        fine=compact(d['x'],d['fs'],oversample=8)['phi_compact']
        coarse_error=np.sqrt(np.mean((coarse-d['phi_direct'])**2))
        fine_error=np.sqrt(np.mean((fine-d['phi_direct'])**2))
        self.assertLess(fine_error,coarse_error/10)

    def test_endpoint_preserves_whole_slow_phase_turns(self):
        fs=2e6; t=np.arange(40000)/fs
        # A restricted search selects 39 kHz; the stronger 40 kHz component
        # makes q accumulate twenty whole turns across this 20 ms record.
        x=np.cos(2*np.pi*39000*t)+2*np.cos(2*np.pi*40000*t+.2)
        d=compact(x,fs,search=(38.5e3,39.5e3),band=(38e3,41e3))
        self.assertAlmostEqual((d['delta_extended'][-1]-d['delta_extended'][0])/(2*np.pi),20)
        np.testing.assert_allclose(np.exp(1j*d['delta_extended'][-1]),
                                   np.exp(1j*d['delta_extended'][0]),atol=1e-12)
        F,f,_=frequency(x,fs,search=(38.5e3,39.5e3))
        _,z=complex_signal(F,f,band=(38e3,41e3)); phi,_=phase(z)
        diff=d['phi_compact']-phi; diff-=2*np.pi*np.rint(diff[0]/(2*np.pi))
        self.assertLess(abs(diff[-1]),.003)


if __name__=='__main__': unittest.main()
