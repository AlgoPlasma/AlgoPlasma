# K05 contribution history (Git author dates; edit times include timezone).
# 2026-10-29 13:23 +08:00 | Yinjian Zhao | git 5604a5bb51cc
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Independent numerical and file-layout checks for the K05 sweep example."""
from pathlib import Path
import struct
import tempfile
import unittest

import numpy as np
from yokogawa_wdf import read_wdf
from analyze_probe_response import (reconstruct, bin_curve, fit_temperature,
                                    operating_scenarios, rc_response)


def fixture(endian="Big"):
    def chunk(kind, value):
        return kind+struct.pack(">Q",len(value))+value+b"\xff"*4
    common=b"%WDF"+struct.pack(">I",64)+b"\0"*24+b"DL350"+b"\0"*27
    raw=struct.pack(">3h",-10,20,-32768)
    hdr=f"""$PublicInfo
Model DL350
Endian {endian}
DataFormat Trace
GroupNumber 1
TraceTotalNumber 1
DataOffset 84
$Group1
TraceNumber 1
BlockNumber 1
TraceName CH3_2
BlockSize 3
VDataType IS2
VResolution 0.25
VOffset 2.0
VIllegalData -32768
VUnit V
HResolution 0.001
HOffset -0.002
HUnit s
$PrivateInfo
StartOffset1 0
TrigTime1 2026/10/14 00:00:00
""".encode("ascii")
    return common+chunk(b"DrAW",b"\0"*8+raw)+chunk(b"XHDR",hdr)+chunk(b"FeND",b"")


class ProbeResponseTests(unittest.TestCase):
    def test_documented_binary_units_and_illegal_code(self):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/"test.WDF";p.write_bytes(fixture());d=read_wdf(p)
        a=d["traces"]["CH3_2"]
        np.testing.assert_allclose(a["values"],[-.5,7,np.nan])
        self.assertEqual(a["dt_s"],.001);self.assertEqual(a["t0_s"],-.002)
        self.assertEqual(a["invalid_count"],1)

    def test_reject_truncation_and_unsupported_endian(self):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/"test.WDF"
            for data in [fixture()[:-2],fixture("Little"),fixture().replace(b"StartOffset1 0",b"StartOffset1 1")]:
                p.write_bytes(data)
                with self.assertRaises(ValueError):read_wdf(p)

    def test_circuit_kvl_and_current_sign(self):
        voltage,current=reconstruct([150,80],[-5,2],1000,100)
        np.testing.assert_allclose(voltage,[45,-18])
        np.testing.assert_allclose(current,[.005,-.002])
        np.testing.assert_allclose(voltage+100+1000*current,[150,80])

    def test_known_temperature_and_current_unit_invariance(self):
        v=np.linspace(-160,20,901)
        i=1e-3*np.exp((v+30)/7)+1e-7*v-3e-4
        curve=np.column_stack([v,i,i,i,np.ones(len(i))])
        fit,_=fit_temperature(curve,[-150,-120],[[-10,5],[-5,10],[0,15]])
        np.testing.assert_allclose([f["te_ev"] for f in fit["fits"]],7,rtol=2e-4)
        curve[:,1:4]*=1000
        other,_=fit_temperature(curve,[-150,-120],[[-10,5],[-5,10],[0,15]])
        np.testing.assert_allclose([f["te_ev"] for f in other["fits"]],7,rtol=2e-4)

    def test_binning_spread_is_not_standard_error(self):
        v=np.repeat([-1.,1.],100);i=np.tile(np.arange(100),2)
        b=bin_curve(v,i,2,20)
        np.testing.assert_allclose(b[:,1:4],np.tile([49.5,15.84,83.16],(2,1)))
        self.assertTrue(np.all(b[:,4]==100))

    def test_load_line_known_constant_ion_current(self):
        v=np.linspace(-100,100,101);i=np.full_like(v,-.001)
        c=np.column_stack([v,i])
        cfg=dict(cathode_to_chamber_scenarios_v=[-20,0,20],resistance_ohm=1000,fast_battery_v=40.5)
        result=operating_scenarios(c,[0,-.001],cfg)
        np.testing.assert_allclose([r["probe_to_chamber_v"] for r in result],[-59.5,-39.5,-19.5])
        np.testing.assert_allclose([r["electron_to_ion_ratio"] for r in result],0)

    def test_rc_phase_with_positive_forward_fourier(self):
        # Choose V=cos(wt); Kirchhoff gives I=V/R + C*dV/dt.
        n=4096;k=13;dt=1e-8;f=k/(n*dt);t=np.arange(n)*dt;r=1000;c=100e-12
        voltage=np.cos(2*np.pi*f*t)
        current=voltage/r-c*2*np.pi*f*np.sin(2*np.pi*f*t)
        z=np.fft.ifft(voltage)[k]/np.fft.ifft(current)[k]
        np.testing.assert_allclose(z/r,rc_response(f,r,c),rtol=1e-13)
        self.assertGreater(np.angle(z),0)
        self.assertEqual(rc_response(0,r,c),1)


if __name__=="__main__":
    unittest.main()
