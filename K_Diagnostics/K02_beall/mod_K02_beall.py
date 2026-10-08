"""@file mod_K02_beall.py
@brief Module entry of K02_beall: aliasing algebra and the Beall spectrum.

@details
Collects the routines of this unit so a caller can import them from one place.
The unit holds the closed-form consequence of measuring with one probe pair --
the folding algebra -- together with the Beall estimator that makes it visible.
K03 removes the resulting ambiguity by combining separations of several lengths;
the two units are the problem and the solution of the same measurement.

@author Zilong PENG (2026/09/02)
"""

from K_Diagnostics.K02_beall.fun_K02_beall_spectrum import fun_K02_beall_spectrum
from K_Diagnostics.K02_beall.fun_K02_beall_wavenumber import fun_K02_beall_wavenumber
from K_Diagnostics.K02_beall.fun_K02_fold_order import fun_K02_fold_order
from K_Diagnostics.K02_beall.fun_K02_fold_wavenumber import fun_K02_fold_wavenumber
from K_Diagnostics.K02_beall.fun_K02_nyquist_wavenumber import (
    fun_K02_nyquist_wavenumber,
)
from K_Diagnostics.K02_beall.fun_K02_peak_wavenumber import fun_K02_peak_wavenumber
from K_Diagnostics.K02_beall.fun_K02_project_wavenumber import (
    fun_K02_project_wavenumber,
)
from K_Diagnostics.K02_beall.fun_K02_separation_magnitude import (
    fun_K02_separation_magnitude,
)
from K_Diagnostics.K02_beall.fun_K02_separation_vector import fun_K02_separation_vector
from K_Diagnostics.K02_beall.fun_K02_wavenumber_edges import fun_K02_wavenumber_edges
from K_Diagnostics.K02_beall.fun_K02_wavenumber_residual import (
    fun_K02_wavenumber_residual,
)

__all__ = [
    "fun_K02_separation_vector",
    "fun_K02_separation_magnitude",
    "fun_K02_nyquist_wavenumber",
    "fun_K02_project_wavenumber",
    "fun_K02_fold_order",
    "fun_K02_fold_wavenumber",
    "fun_K02_wavenumber_edges",
    "fun_K02_beall_wavenumber",
    "fun_K02_beall_spectrum",
    "fun_K02_peak_wavenumber",
    "fun_K02_wavenumber_residual",
]
