# K05 contribution history (Git author dates; edit times include timezone).
# 2026-10-23 16:13 +08:00 | Yinjian Zhao | git 482110a190d6
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Build two real Sphinx pages to check bilingual, cross-page equation links.

Run from the repository root: python -m unittest discover -s docs/tests -v
"""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "source"


class K05EquationTests(unittest.TestCase):
    def build(self, extra="", invalid=False):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        (root / "conf.py").write_text(
            f"import sys\nsys.path.insert(0, {str(SOURCE / '_ext')!r})\n"
            "extensions = ['k05_equations']\nmaster_doc = 'index'\n"
            f"html_static_path = [{str(SOURCE / '_static')!r}]\n", encoding="utf-8")
        (root / "_data").mkdir()
        registry = {"wave": 1, "envelope": 2}
        if invalid:
            registry["envelope"] = 1
        (root / "_data/k05_equations.json").write_text(json.dumps(registry), encoding="utf-8")
        (root / "index.rst").write_text("Test\n====\n\n.. toctree::\n\n   first\n   second\n", encoding="utf-8")
        (root / "first.rst").write_text(
            "First\n=====\n\n.. container:: ap-lang ap-lang-en\n\n"
            "   .. k05:equation:: wave\n      :lang: en\n\n      u=A\n\n"
            "   See :k05:eq:`envelope`.\n\n"
            ".. container:: ap-lang ap-lang-zh\n\n"
            "   .. k05:equation:: wave\n      :lang: zh\n\n      u=A\n\n"
            "   See :k05:eq:`envelope`.\n\n" + extra, encoding="utf-8")
        (root / "second.rst").write_text(
            "Second\n======\n\n.. container:: ap-lang ap-lang-en\n\n"
            "   .. k05:equation:: envelope\n      :lang: en\n\n      A=1\n\n"
            "   See :k05:eq:`wave`.\n\n"
            ".. container:: ap-lang ap-lang-zh\n\n"
            "   .. k05:equation:: envelope\n      :lang: zh\n\n      A=1\n\n"
            "   See :k05:eq:`wave`.\n", encoding="utf-8")
        out = root / "_build"
        result = subprocess.run([sys.executable, "-m", "sphinx", "-b", "html",
                                 "-j", "2", "-W", "--keep-going", str(root), str(out)],
                                capture_output=True, text=True)
        return root, out, result

    def test_cross_page_language_numbers_and_incremental_build(self):
        root, out, result = self.build()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        first = (out / "first.html").read_text(encoding="utf-8")
        self.assertEqual(first.count('(K05.1)'), 2)
        for lang in ["en", "zh"]:
            self.assertIn(f'href="second.html#equation-k05-envelope-{lang}"', first)
        # A subsequent page rebuild must clear its old entries, not report duplicates.
        page = root / "first.rst"
        page.write_text(page.read_text(encoding="utf-8") + "\nChanged prose.\n", encoding="utf-8")
        result = subprocess.run([sys.executable, "-m", "sphinx", "-b", "html", "-W",
                                 str(root), str(out)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_rejects_unknown_id(self):
        _, _, result = self.build(".. k05:equation:: unknown\n\n   u=0\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unregistered K05 equation", result.stdout + result.stderr)

    def test_rejects_duplicate_language_target(self):
        _, _, result = self.build(".. k05:equation:: wave\n   :lang: en\n\n   u=A\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Duplicate K05 equation", result.stdout + result.stderr)

    def test_rejects_duplicate_numbers(self):
        _, _, result = self.build(invalid=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("distinct positive integers", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
