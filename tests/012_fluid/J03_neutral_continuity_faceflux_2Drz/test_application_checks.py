#!/usr/bin/env python3
"""Fast tests for application acceptance and input validation; no transport runs."""
import tempfile
import unittest
import subprocess
import numpy as np
from pathlib import Path
from plot_application import assess_balance, validate_density
from validate_application_inputs import validate


class ApplicationChecks(unittest.TestCase):
    def test_density_validation(self):
        mask = np.array([[True, False], [True, True]])
        field = np.ones((2, 2))
        field[0, 1] = np.nan  # Inactive cells do not participate.
        validate_density(field, mask, "J02")
        for value in (-1.0, np.nan, np.inf):
            with self.subTest(value=value):
                field[1, 0] = value
                with self.assertRaisesRegex(ValueError, "J02.*i=2, k=1"):
                    validate_density(field, mask, "J02")

    def test_driver_rejects_invalid_reference(self):
        root = Path(__file__).parent
        executable = root / "application_reference/build/application_reference/run_J03_application_reference.out"
        if not executable.exists():
            self.skipTest("build application_reference/make.sh first to test the Fortran driver")
        with tempfile.TemporaryDirectory() as folder:
            directory = Path(folder)
            for value in (-1.0, np.nan, np.inf):
                with self.subTest(value=value):
                    density = np.ones((256, 256))
                    density[64, 0] = value  # Active cell (65,1), Fortran indexing.
                    density.ravel(order="F").tofile(directory / "na_sn_rz_f64.bin")
                    result = subprocess.run(
                        [str(executable), "ION", str(root / "application_inputs"), folder, folder],
                        capture_output=True, text=True, timeout=10)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("invalid J02 reference density at i=65, k=1", result.stdout)
                    self.assertFalse((directory / "na_cont_rz_f64.bin").exists())

    def record(self, **changes):
        result = dict(inflow_rate="3", outflow_rate="2", production_rate="1",
                      removal_rate="2", scaled_residual="1e-10")
        result.update(changes)
        return result

    def test_balanced(self):
        self.assertTrue(assess_balance(self.record())[0])

    def test_unbalanced(self):
        self.assertFalse(assess_balance(self.record(outflow_rate="1"))[0])

    def test_large_residual(self):
        self.assertFalse(assess_balance(self.record(scaled_residual="1"))[0])

    def test_nonfinite_and_missing(self):
        with self.assertRaises(ValueError):
            assess_balance(self.record(removal_rate="nan"))
        with self.assertRaises(KeyError):
            assess_balance({})

    def test_negative_rate(self):
        with self.assertRaises(ValueError):
            assess_balance(self.record(inflow_rate="-1"))

    def test_published_inputs(self):
        validate(Path(__file__).parent / "application_inputs")

    def test_missing_and_bad_grid(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            with self.assertRaises(FileNotFoundError):
                validate(root)
            # These are deliberately invalid generated test data, not source files.
            (root / "grid_r.dat").write_text("# empty grid\n")
            with self.assertRaises(ValueError):
                validate(root)


if __name__ == "__main__":
    unittest.main()
