"""K04: Pool sample sums/counts after excluding one complete record."""

import numpy as np


def fun_K04_mean_other_records(sums, counts, r):
    """Pool sample sums/counts after excluding one complete record.

    sums and counts have shape (J, B); J >= 3; r is a zero-based held-out
    record index. Returns mu (B,) in V and K_train (B,) counts. Samples,
    not records, have equal weight. Empty training bins raise ValueError.
    K04 equations (9)-(10)."""
    sums, counts = np.asarray(sums, dtype=float), np.asarray(counts)
    if sums.ndim != 2 or sums.shape != counts.shape or not np.isfinite(sums).all() or not np.isfinite(counts).all():
        raise ValueError("Expected finite sums and counts with shape (records, bins)")
    if np.any(counts < 0) or np.any(counts != np.floor(counts)):
        raise ValueError("Counts must be nonnegative integers")
    if isinstance(r, (bool, np.bool_)) or not isinstance(r, (int, np.integer)):
        raise ValueError("Held-out index must be an integer")
    if len(sums) < 3 or not 0 <= r < len(sums):
        raise ValueError("Use at least 3 complete records")
    S_train = np.sum([s for j, s in enumerate(sums) if j != r], axis=0)
    K_train = np.sum([k for j, k in enumerate(counts) if j != r], axis=0)
    if np.any(K_train == 0):
        raise ValueError("Empty phase bin: check data coverage")
    return S_train/K_train, K_train
