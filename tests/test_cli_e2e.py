from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from px.cli import main


class PublishingCliE2ETests(unittest.TestCase):
    def test_public_cli_build_list_verify_round_trip(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "article.tex").write_text(
                r"\documentclass{article}\begin{document}Hello\end{document}", encoding="utf-8"
            )
            (root / "workspace.yml").write_text(
                """schema_version: 2
project:
  name: e2e-fixture
  type: collection
  languages: [en, fa]
build:
  output_dir: build
  timeout_seconds: 10
documents:
  sample:
    type: article
    title: E2E sample
    editions:
      en: {source: article.tex, engine: pdflatex}
""",
                encoding="utf-8",
            )

            def fake_latexmk(command, *, cwd, env, timeout):
                outdir = Path(next(arg.split("=", 1)[1] for arg in command if arg.startswith("-outdir=")))
                outdir.mkdir(parents=True, exist_ok=True)
                (outdir / "article.pdf").write_bytes(b"%PDF-1.7\nE2E\n%%EOF\n")

            with patch("px.project.run_checked", side_effect=fake_latexmk):
                self.assertEqual(main(["--root", str(root), "build"]), 0)
            self.assertEqual(main(["--root", str(root), "list"]), 0)
            self.assertEqual(main(["--root", str(root), "verify"]), 0)
            manifest = json.loads((root / "build/manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(manifest["summary"]["completed"], 1)
            self.assertEqual(manifest["results"][0]["status"], "success")


if __name__ == "__main__":
    unittest.main()
