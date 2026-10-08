"""K04: orchestrate the single-point, whole-record holdout calculation."""
import numpy as np
from .fun_K04_find_frequency import fun_K04_find_frequency
from .fun_K04_make_complex_signal import fun_K04_make_complex_signal
from .fun_K04_mark_position import fun_K04_mark_position
from .fun_K04_put_into_bins import fun_K04_put_into_bins
from .fun_K04_mean_other_records import fun_K04_mean_other_records
from .fun_K04_mean_to_coefficients import fun_K04_mean_to_coefficients
from .fun_K04_coefficients_to_grid import fun_K04_coefficients_to_grid
from .fun_K04_grid_to_time import fun_K04_grid_to_time


def fun_K04_extract_waveform(records, fs, held_out=0, bins=256, cutoff=3e6,
                             grid_size=4096, search=(35e3, 45e3), band=(25e3, 55e3)):
    """Extract C and R for one held-out record, without file I/O.

    records: sequence of J>=3 finite real voltage arrays (N_j,), sampled at
    the same fs in Hz under comparable conditions at one spatial point.
    Record lengths may differ. held_out is a zero-based record index.
    bins is even >=4; cutoff/search/band use Hz; grid_size is a point count.
    The held-out record supplies its own phase but no training voltages.

    Return dict: C and R (N_r,) in V; frequencies (J,) Hz; positions, a list
    of theta arrays (N_j,) radians; sums/counts (J,bins); mu/K_train (bins,);
    a (bins//2+1,) complex V; gamma/w (grid_size,) radians/V; H integer.
    F/f/F_hat/z/phi/theta describe the held-out record and permit inspection.
    All records retain their original phase origins. Near-zero complex
    amplitudes and nonstationary waveforms require further data assessment.
    """
    if isinstance(held_out, (bool, np.bool_)) or not isinstance(held_out, (int, np.integer)):
        raise ValueError("held_out must be an integer")
    if len(records) < 3 or not 0 <= held_out < len(records):
        raise ValueError("Use >=3 records and a valid held-out index")
    if isinstance(bins, (bool, np.bool_)) or not isinstance(bins, (int, np.integer)) or bins < 4 or bins % 2:
        raise ValueError("bins must be an even integer >=4")
    frequencies, positions, sums, counts = [], [], [], []
    result = {}
    for j, x in enumerate(records):
        F, f, f0 = fun_K04_find_frequency(x, fs, search)
        F_hat, z = fun_K04_make_complex_signal(F, f, band)
        if not band[0] <= f0 <= band[1]:
            raise ValueError("The phase band must contain the selected main frequency")
        phi, theta = fun_K04_mark_position(z)
        S, K = fun_K04_put_into_bins(x, theta, bins)
        frequencies.append(f0)
        positions.append(theta)
        sums.append(S)
        counts.append(K)
        if j == held_out:
            result.update(F=F, f=f, f0=f0, F_hat=F_hat, z=z, phi=phi, theta=theta)
    mu, K_train = fun_K04_mean_other_records(sums, counts, held_out)
    a = fun_K04_mean_to_coefficients(mu)
    gamma, w, H = fun_K04_coefficients_to_grid(a, frequencies[held_out], fs, cutoff, grid_size)
    C = fun_K04_grid_to_time(positions[held_out], gamma, w)
    result.update(C=C, R=np.asarray(records[held_out])-C, frequencies=np.asarray(frequencies),
                  positions=positions, sums=np.asarray(sums), counts=np.asarray(counts),
                  mu=mu, K_train=K_train, a=a, gamma=gamma, w=w, H=H)
    return result
