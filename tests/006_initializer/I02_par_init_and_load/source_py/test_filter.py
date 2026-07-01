"""
Test the binary file format and domain-filtering logic of sub_I02_load_init_particles_bin.

The Fortran routine reads a stream-unformatted binary where each particle is
6 consecutive float64 values (x, y, z, vx, vy, vz), and keeps only particles
satisfying:
    il(d)-1 <= x(d) < iu(d)   for d = 1, 2, 3

This script verifies that logic (and the binary format) without requiring MPI.
"""

import os
import tempfile
import numpy as np


def write_bin(fname, particles):
    """Write (N, 6) float64 array as raw stream binary (no Fortran record markers)."""
    particles.astype(np.float64).tofile(fname)


def read_bin(fname, np_load):
    """Read np_load particles from binary file."""
    data = np.fromfile(fname, dtype=np.float64)
    return data.reshape(-1, 6)[:np_load]


def apply_filter(particles, il, iu):
    """Replicate Fortran filter: keep if il(d)-1 <= x(d) < iu(d)."""
    il = np.array(il, dtype=np.float64)
    iu = np.array(iu, dtype=np.float64)
    x = particles[:, 0]
    y = particles[:, 1]
    z = particles[:, 2]
    mask = ((x >= il[0]-1) & (x < iu[0]) &
            (y >= il[1]-1) & (y < iu[1]) &
            (z >= il[2]-1) & (z < iu[2]))
    return particles[mask]


def run_test(name, particles, il, iu, expected_count, expected_data=None):
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        fname = f.name
    try:
        write_bin(fname, particles)
        read_back = read_bin(fname, len(particles))
        kept = apply_filter(read_back, il, iu)
        n_kept = len(kept)

        ok = (n_kept == expected_count)
        if expected_data is not None and ok:
            ok = np.allclose(np.sort(kept[:,0]), np.sort(expected_data[:,0]))

        status = "PASS" if ok else "FAIL"
        print(f"  {name}: kept={n_kept}, expected={expected_count}  {status}")
    finally:
        os.unlink(fname)


def main():
    print("=" * 50)
    print("I02 binary format + domain filter tests")
    print("=" * 50)

    il = [3, 3, 3]
    iu = [7, 7, 7]
    # Fortran domain: [il(d)-1, iu(d)) = [2.0, 7.0) in each direction

    # A: all particles inside domain
    par_A = np.array([
        [2.5, 3.5, 4.5,  1.0, 0.0, 0.0],
        [3.0, 4.0, 5.0,  0.0, 1.0, 0.0],
        [6.9, 6.9, 6.9,  0.0, 0.0, 1.0],
        [2.0, 2.0, 2.0,  0.0, 0.0, 0.0],   # exactly at lower bound: included
    ], dtype=np.float64)
    run_test("A_all_inside (n=4)", par_A, il, iu, 4)

    # B: all particles outside domain
    par_B = np.array([
        [1.9, 3.5, 4.5,  0.0, 0.0, 0.0],   # x < 2.0
        [7.0, 3.5, 4.5,  0.0, 0.0, 0.0],   # x >= 7.0 (upper bound excluded)
        [3.5, 1.9, 4.5,  0.0, 0.0, 0.0],   # y < 2.0
        [3.5, 7.0, 4.5,  0.0, 0.0, 0.0],   # y >= 7.0
        [3.5, 3.5, 1.9,  0.0, 0.0, 0.0],   # z < 2.0
        [3.5, 3.5, 7.0,  0.0, 0.0, 0.0],   # z >= 7.0
    ], dtype=np.float64)
    run_test("B_all_outside (n=6)", par_B, il, iu, 0)

    # C: mixed — par_A (4 in) + par_B (0 in) = 4 kept
    par_C = np.vstack([par_A, par_B])
    run_test("C_mixed (n=10, expect 4 kept)", par_C, il, iu, 4)

    # D: boundary conditions
    par_D = np.array([
        [2.0,   3.5, 3.5, 0.0, 0.0, 0.0],  # x = 2.0 → included
        [6.999, 3.5, 3.5, 0.0, 0.0, 0.0],  # x < 7.0 → included
        [7.0,   3.5, 3.5, 0.0, 0.0, 0.0],  # x = 7.0 → excluded
        [1.999, 3.5, 3.5, 0.0, 0.0, 0.0],  # x < 2.0 → excluded
    ], dtype=np.float64)
    run_test("D_boundary (n=4, expect 2 kept)", par_D, il, iu, 2)

    # E: round-trip fidelity — verify particle data is preserved exactly
    rng = np.random.default_rng(42)
    par_E = rng.random((20, 6)).astype(np.float64)
    par_E[:, :3] = par_E[:, :3] * 5.0 + 2.0   # positions in [2.0, 7.0)
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        fname = f.name
    write_bin(fname, par_E)
    read_back = read_bin(fname, 20)
    os.unlink(fname)
    if np.array_equal(par_E, read_back):
        print("  E_roundtrip (20 particles, float64)  PASS")
    else:
        print("  E_roundtrip  FAIL")

    print("Done.")


if __name__ == "__main__":
    main()
