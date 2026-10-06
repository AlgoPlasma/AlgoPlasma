"""Deterministic artificial signals used by the K04 documentation."""
import numpy as np


def synthetic_data(seed=20261004):
    """Return t (N,), fs, ten voltage records, and independent generator truth.

    Exact K04 Appendix A parameters: 8 MHz, 160000 samples, 20 ms per record.
    Truth is used for verification only, never supplied to extraction.
    """
    rng = np.random.default_rng(seed)
    fs, N, J = 8_000_000, 160_000, 10
    t = np.arange(N) / fs
    xs, truths = [], []
    for j in range(J):
        ph = 2*np.pi*(40_000 + 50*(j-5))*t + rng.uniform(-np.pi, np.pi)
        ph += 0.18*np.sin(2*np.pi*250*t)
        known = (0.6 + 1.8*np.cos(ph) + 0.5*np.cos(2*ph-0.7)
                 + 0.23*np.sin(5*ph) + 0.07*np.cos(12*ph))
        noise_F = np.fft.rfft(rng.normal(size=N))
        noise_f = np.fft.rfftfreq(N, 1/fs)
        noise_F[(noise_f < 150e3) | (noise_f > 1e6)] = 0
        noise = np.fft.irfft(noise_F, n=N)
        noise /= np.std(noise)
        strength = 0.18 + 0.16*(1 + np.cos(ph-0.8))
        xs.append(known + strength*noise)
        truths.append(known)
    return t, fs, xs, truths


def compact_phase_data():
    """Return t, fs, voltage x and independent phase truth for Appendix B."""
    fs, N = 8_000_000.0, 160_000
    t = np.arange(N)/fs
    phi_known = 2*np.pi*39_750*t + 0.37 + 0.18*np.sin(2*np.pi*250*t)
    x = (0.6 + 1.8*np.cos(phi_known) + 0.4*np.cos(2*phi_known-0.7)
         + 0.08*np.cos(2*np.pi*300_000*t))
    return t, fs, x, phi_known
