"""Exercise clean.sh in disposable copies; never delete the checkout's results."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(os.name == 'posix' and shutil.which('bash'), 'cleanup checks require POSIX Bash')
class CleanupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='k04-clean-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.unit = self.root/'K04 folder with spaces'
        self.unit.mkdir()
        source = Path(__file__).resolve().parent
        shutil.copy2(source/'clean.sh', self.unit/'clean.sh')
        (self.unit/'test_K04_breathing_waveform.py').write_text('# source marker\n')

    def clean(self):
        return subprocess.run(['bash', str(self.unit/'clean.sh')], cwd=self.root,
                              text=True, capture_output=True, check=False)

    def test_removes_default_outputs_and_caches_but_keeps_source(self):
        for relative in ('output/figures/result.png', 'output/metrics.json',
                         '__pycache__/module.pyc', 'source_py/__pycache__/example.pyc',
                         'tests/__pycache__/test.pyc'):
            path=self.unit/relative; path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text('generated')
        (self.unit/'notes.txt').write_text('user notes')
        (self.unit/'custom-results').mkdir()
        (self.unit/'custom-results/keep.txt').write_text('custom result')
        result=self.clean()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse((self.unit/'output').exists())
        self.assertFalse(list(self.unit.rglob('__pycache__')))
        self.assertEqual((self.unit/'notes.txt').read_text(),'user notes')
        self.assertTrue((self.unit/'test_K04_breathing_waveform.py').is_file())
        self.assertTrue((self.unit/'custom-results/keep.txt').is_file())
        self.assertEqual(self.clean().returncode,0)  # Already clean is also successful.

    def test_does_not_follow_output_or_directory_symlinks(self):
        external=self.root/'external'; (external/'__pycache__').mkdir(parents=True)
        (external/'__pycache__/keep.pyc').write_text('external cache')
        (external/'keep.txt').write_text('external data')
        (self.unit/'output').symlink_to(external,target_is_directory=True)
        (self.unit/'source_py').symlink_to(external,target_is_directory=True)
        result=self.clean()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse((self.unit/'output').is_symlink())
        self.assertTrue((self.unit/'source_py').is_symlink())
        self.assertTrue((external/'__pycache__/keep.pyc').is_file())
        self.assertTrue((external/'keep.txt').is_file())

    def test_refuses_a_misplaced_script(self):
        (self.unit/'test_K04_breathing_waveform.py').unlink()
        (self.unit/'output').mkdir()
        (self.unit/'output/keep.txt').write_text('must remain')
        self.assertNotEqual(self.clean().returncode,0)
        self.assertTrue((self.unit/'output/keep.txt').is_file())


if __name__ == '__main__':
    unittest.main()
