"""K04: evaluate narrowband phase on a shorter inverse-FFT grid."""
import numpy as np
from .fun_K04_find_frequency import fun_K04_find_frequency
from .fun_K04_mark_position import fun_K04_mark_position


def fun_K04_compact_phase(x, fs, oversample=4, search=(35e3, 45e3), band=(25e3, 55e3)):
    """Return compact phase and intermediate arrays for the knowledge note.

    x: real (N,) voltage; fs/search/band: Hz; oversample: finite factor >=2.
    Selected contiguous FFT bins are shifted by fL, then f0-fL. M_base is
    the next power of two >= oversample*L. Normalize the short IFFT by M/N,
    append q[0] before unwrapping, interpolate slow phase, restore 2*pi*f0*t.

    Returns dict with phi_compact (N,) radians; delta_native (N,) radians;
    F/f (N,) complex/Hz; f0/fL Hz, kL and L integers; band (L,) FFT indices;
    M_base integer; tau/v/q (M_base,) seconds/complex V/complex V;
    delta_extended (M_base+1,) radians. No file I/O or full-length IFFT.
    The oversampling factor is a numerical choice, not an accuracy guarantee.
    """
    if not np.isfinite(oversample) or oversample < 2:
        raise ValueError("oversample must be finite and >=2")
    F, f, f0 = fun_K04_find_frequency(x, fs, search)
    lo, hi = band
    if not 0 < lo < hi <= np.max(f) or not lo <= f0 <= hi:
        raise ValueError("Choose a positive phase band containing the main peak")
    band = np.flatnonzero((f >= lo) & (f <= hi))
    if not band.size or not np.any(np.abs(F[band]) > 0):
        raise ValueError("No selected signal from which to estimate phase")
    N, T = len(x), len(x)/fs
    L, kL = len(band), int(band[0])
    fL = f[kL]
    M_base = 1 << int(np.ceil(np.log2(oversample*L)))
    tau = np.arange(M_base)*T/M_base
    A = np.zeros(M_base, dtype=complex)
    A[:L] = F[band]
    v = np.fft.ifft(A)*M_base/N
    q = v*np.exp(-2j*np.pi*(f0-fL)*tau)
    delta_extended, _ = fun_K04_mark_position(np.r_[q, q[0]])
    t = np.arange(N)/fs
    delta_native = np.interp(t, np.r_[tau, T], delta_extended)
    phi_compact = 2*np.pi*f0*t + delta_native
    return dict(phi_compact=phi_compact, delta_native=delta_native,
                F=F, f=f, f0=f0, fL=fL, kL=kL, L=L, band=band,
                M_base=M_base, tau=tau, v=v, q=q, delta_extended=delta_extended)
