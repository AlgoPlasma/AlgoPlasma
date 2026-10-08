"""Locate the checkout from this test case, without a machine-specific path."""
from pathlib import Path
import sys

# Keep imported numerical modules free of generated cache directories.
sys.dont_write_bytecode = True
CASE_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_DIR.parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))
