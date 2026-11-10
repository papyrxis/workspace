from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from px.config import ConfigError, load_config
from px.project import build_documents, list_documents, plan_documents, verify_manifest
from px.build import BuildError


class MultiDocumentProjectTests(unittest.TestCase):
    def _project(self, root: Path) -> dict:
        (root / "papers").mkdir()
        (root / "books").mkdir()
        for path in ("papers/a.tex", "papers/b.tex", "books/en.tex", "books/fa.tex"):
            (root / path).write_text(r"\documentclass{article}\begin{document}fixture\end{document}", encoding="utf-8")
        (root / "workspace.yml").write_text(
            """schema_version: 2
project:
  name: fixture
  type: collection
  title: Fixture Collection
  languages: [en, fa]
build:
  output_dir: build
  default_engine: xelatex
  timeout_seconds: 30
documents:
  paper-a:
    type: article
    title: First paper
    editions:
      en: {source: papers/a.tex, engine: pdflatex}
  paper-b:
    type: article
    title: Second paper
    editions:
      en: {source: papers/b.tex, engine: lualatex}
  handbook:
    type: book
    title: Handbook
    editions:
      en: {source: books/en.tex, engine: pdflatex}
      fa: {source: books/fa.tex, engine: xelatex}
""",
            encoding="utf-8",
        )
        return load_config(root)

    def test_v2_loads_and_plans_all_documents_and_mixed_engines(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            plan = plan_documents(root, config)
            self.assertEqual(len(plan), 4)
            self.assertEqual({x["engine"] for x in plan}, {"pdflatex", "xelatex", "lualatex"})
            self.assertEqual(plan[0]["output"].relative_to(root).as_posix(), "build/paper-a/en/a.pdf")

    def test_document_and_edition_selection(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            plan = plan_documents(root, config, "handbook", "fa")
            self.assertEqual([(x["document_id"], x["edition"]) for x in plan], [("handbook", "fa")])

    def test_rejects_traversal_and_bad_engine(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)
            path = root / "workspace.yml"
            text = path.read_text(encoding="utf-8").replace("source: papers/a.tex", "source: ../escape.tex")
            path.write_text(text, encoding="utf-8")
            with self.assertRaises(ConfigError):
                load_config(root)

    def test_build_manifest_and_sha_verification(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)

            def fake_latexmk(command, *, cwd, env, timeout):
                outdir = Path(next(arg.split("=", 1)[1] for arg in command if arg.startswith("-outdir=")))
                source = Path(command[-1])
                outdir.mkdir(parents=True, exist_ok=True)
                jobname = next(arg.split("=", 1)[1] for arg in command if arg.startswith("-jobname="))
                (outdir / f"{jobname}.pdf").write_bytes(b"%PDF-1.7\nfixture\n%%EOF\n")

            with patch("px.project.run_checked", side_effect=fake_latexmk):
                manifest = build_documents(root, config, keep_going=True)
            self.assertEqual(manifest["summary"]["completed"], 4)
            self.assertEqual(len(list_documents(root, config)), 4)
            self.assertEqual(verify_manifest(root, config)["checked"], 4)

            pdf = root / "build/handbook/fa/fa.pdf"
            pdf.write_bytes(b"%PDF-1.7\ntampered\n%%EOF\n")
            with self.assertRaises(BuildError):
                verify_manifest(root, config)


if __name__ == "__main__":
    unittest.main()
