"""@file mod_K01_signal_spectra.py
@brief Module entry of K01_signal_spectra: segmented spectra of a probe pair.

@details
Collects the routines of this unit so a caller can import them from one place,
the Python counterpart of a Fortran module wrapper that includes its subroutine
files. The unit turns two raw probe records into the quantities K02 and K03
consume: segment spectra, power spectra, coherence, and the cross phase of the
pair with its mean and variance. It performs no file I/O.

@author Zilong PENG (2026/09/02)
"""

from K_Diagnostics.K01_signal_spectra.fun_K01_coherence import fun_K01_coherence
from K_Diagnostics.K01_signal_spectra.fun_K01_cross_phase import fun_K01_cross_phase
from K_Diagnostics.K01_signal_spectra.fun_K01_pair_power import fun_K01_pair_power
from K_Diagnostics.K01_signal_spectra.fun_K01_phase_mode_statistics import (
    fun_K01_phase_mode_statistics,
)
from K_Diagnostics.K01_signal_spectra.fun_K01_power_spectrum import (
    fun_K01_power_spectrum,
)
from K_Diagnostics.K01_signal_spectra.fun_K01_segment_ffts import fun_K01_segment_ffts
from K_Diagnostics.K01_signal_spectra.fun_K01_wrap_to_pi import fun_K01_wrap_to_pi

__all__ = [
    "fun_K01_wrap_to_pi",
    "fun_K01_segment_ffts",
    "fun_K01_power_spectrum",
    "fun_K01_coherence",
    "fun_K01_cross_phase",
    "fun_K01_pair_power",
    "fun_K01_phase_mode_statistics",
]
