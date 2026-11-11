from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

from px.process import CommandError, run_checked, run_quiet


class ProcessDecodingTests(unittest.TestCase):
    def test_run_checked_replaces_invalid_utf8_in_success_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            script = "import os; os.write(1, b'valid-\\xd9-tail'); os.write(2, b'diagnostic-\\xd9')"
            result = run_checked([sys.executable, "-c", script], cwd=Path(tmp))
        self.assertIn("valid-�-tail", result.stdout)
        self.assertIn("diagnostic-�", result.stderr)

    def test_run_checked_preserves_failure_diagnostics_with_invalid_utf8(self):
        with tempfile.TemporaryDirectory() as tmp:
            script = "import os; os.write(2, b'failure-\\xd9-detail'); raise SystemExit(7)"
            with self.assertRaises(CommandError) as caught:
                run_checked([sys.executable, "-c", script], cwd=Path(tmp))
        self.assertEqual(caught.exception.code, 7)
        self.assertIn("failure-�-detail", caught.exception.stderr)

    def test_run_quiet_replaces_invalid_utf8(self):
        with tempfile.TemporaryDirectory() as tmp:
            script = "import os; os.write(1, b'out-\\xd9'); os.write(2, b'err-\\xd9')"
            code, stdout, stderr = run_quiet([sys.executable, "-c", script], cwd=Path(tmp))
        self.assertEqual(code, 0)
        self.assertIn("out-�", stdout)
        self.assertIn("err-�", stderr)


if __name__ == "__main__":
    unittest.main()
