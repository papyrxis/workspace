from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path

from px.build import BuildError, _inside, valid_pdf
from px.config import ConfigError, deep_merge, load_config


class ConfigTests(unittest.TestCase):
    def test_yaml_values_override_defaults_recursively(self) -> None:
        merged = deep_merge(
            {"project": {"type": "book", "title": "Default"}, "export": {"targets": ["devto"]}},
            {"project": {"title": "Custom"}, "export": {"targets": ["ieee"]}},
        )
        self.assertEqual(merged["project"], {"type": "book", "title": "Custom"})
        self.assertEqual(merged["export"]["targets"], ["ieee"])

    def test_yaml_loads_independent_language_engines(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "workspace.yml").write_text(
                "schema_version: 1\nproject:\n  type: book\n  languages: [en, fa]\n"
                "build:\n  entries:\n    en: {source: en/main.tex, engine: pdflatex}\n"
                "    fa: {source: fa/main.tex, engine: xelatex}\n",
                encoding="utf-8",
            )
            cfg = load_config(root)
            self.assertEqual(cfg["build"]["entries"]["fa"]["engine"], "xelatex")

    def test_rejects_traversal_and_unknown_engine(self) -> None:
        for output, engine in (("../outside", "xelatex"), ("build", "tectonic")):
            with tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / "workspace.yml").write_text(
                    "schema_version: 1\nproject:\n  type: article\n  languages: [en]\n"
                    f"build:\n  output_dir: {output}\n  entries:\n    en: {{source: main.tex, engine: {engine}}}\n",
                    encoding="utf-8",
                )
                with self.assertRaises(ConfigError):
                    load_config(root)

    @unittest.skipIf(os.name == "nt", "symlink creation may require Windows Developer Mode")
    def test_resolved_symlink_cannot_escape_project(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as outside:
            root = Path(tmp).resolve()
            (root / "linked").symlink_to(Path(outside), target_is_directory=True)
            with self.assertRaises(BuildError):
                _inside(root, "linked/output", "build.output_dir")

    def test_pdf_validation_checks_header_and_eof(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            good = Path(tmp) / "good.pdf"
            bad = Path(tmp) / "bad.pdf"
            good.write_bytes(b"%PDF-1.7\nbody\n%%EOF\n")
            bad.write_bytes(b"%PDF-1.7\nbody without end")
            self.assertTrue(valid_pdf(good))
            self.assertFalse(valid_pdf(bad))


if __name__ == "__main__":
    unittest.main()
