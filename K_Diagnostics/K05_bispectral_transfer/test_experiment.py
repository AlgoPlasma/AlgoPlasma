"""Numerical and binary-format checks independent of the experimental files."""
import struct
import tempfile
import unittest
from pathlib import Path

import numpy as np
from scipy import signal

from siglent_v4 import read_capture
from analyze_experiment import coefficients, psd_from_coefficients, bicoherence


class ExperimentTests(unittest.TestCase):
    def test_binary_units_endian_and_rejection(self):
        for big in (False, True):
            h=bytearray(4096)
            ui=lambda o,v:struct.pack_into("<I",h,o,v)
            def q(o,v,unit):
                struct.pack_into("<dI7i",h,o,v,8,*unit)
            volt=(0,1,1,0,1,0,1); sec=(0,0,1,0,1,1,1)
            ui(0,4);ui(4,4096);ui(8,1);ui(0x1ec,4)
            q(0x18,2,volt);q(0xb8,.5,volt);q(0x19c,.1,sec);q(0x1c4,0,sec)
            q(0x1f0,4,(0,0,0,0,0,0,0));ui(0x26c,10);ui(0x270,7680)
            struct.pack_into("<d",h,0x244,1);h[0x264]=1;h[0x265]=int(big)
            codes=np.array([32768,40448,25088,32784],dtype=">u2" if big else "<u2")
            with tempfile.TemporaryDirectory() as tmp:
                p=Path(tmp)/"capture.bin";p.write_bytes(h+codes.tobytes())
                m,v=read_capture(p,offset_sign=1)
                np.testing.assert_allclose(v,[.5,2.5,-1.5,.5+16/3840])
                _,fluct=read_capture(p)
                _,minus=read_capture(p,offset_sign=-1)
                np.testing.assert_allclose(fluct,v-v.mean(),atol=1e-15)
                np.testing.assert_allclose(fluct,minus-minus.mean(),atol=1e-15)
                self.assertEqual(m["channel"],1)
                p.write_bytes(p.read_bytes()[:-1])
                with self.assertRaises(ValueError):read_capture(p)

    def test_psd_parseval_and_welch(self):
        rng=np.random.default_rng(4);x=rng.normal(size=16384);n=256;fs=1000
        c,w=coefficients(x,n);s=psd_from_coefficients(c,w,fs)
        seg=x.reshape(-1,n);seg=seg-seg.mean(axis=1,keepdims=True)
        np.testing.assert_allclose(s.sum(axis=1)*fs/n,np.mean((seg*w)**2,axis=1)/np.mean(w*w))
        _,expected=signal.welch(x,fs,window=w,nperseg=n,noverlap=0)
        np.testing.assert_allclose(s.mean(axis=0),expected,rtol=1e-12)

    def test_fourier_sign_and_cross_phase(self):
        n=256;k=16;theta=.4;delay=3
        t=np.arange(n);x=np.cos(2*np.pi*k*t/n+theta)
        y=np.cos(2*np.pi*k*(t-delay)/n+theta)
        X,_=coefficients(x,n);Y,_=coefficients(y,n)
        self.assertAlmostEqual(np.angle(X[0,k]),-theta)
        self.assertAlmostEqual(np.angle(Y[0,k]*X[0,k].conjugate()),2*np.pi*k*delay/n)

    def test_bicoherence_phase_ensemble_and_bounds(self):
        rng=np.random.default_rng(44);r=4096;c=np.zeros((r,33),dtype=complex)
        a,b=rng.uniform(-np.pi,np.pi,size=(2,r))
        c[:,3]=np.exp(1j*a);c[:,5]=np.exp(1j*b);c[:,8]=np.exp(1j*(a+b+.6))
        bc,B=bicoherence(c,64,64,20)
        self.assertAlmostEqual(bc[3,5],1);self.assertAlmostEqual(np.angle(B[3,5]),-.6)
        c[:,8]=np.exp(1j*rng.uniform(-np.pi,np.pi,r))
        bc,_=bicoherence(c,64,64,20)
        self.assertLess(bc[3,5],.005)
        self.assertLessEqual(np.nanmax(bc),1+1e-12)


if __name__ == "__main__":
    unittest.main()
