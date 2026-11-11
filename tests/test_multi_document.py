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

    def test_output_names_are_isolated_between_documents(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            config["documents"]["paper-a"]["editions"]["en"]["output_name"] = "shared"
            config["documents"]["paper-b"]["editions"]["en"]["output_name"] = "shared"
            plan = plan_documents(root, config)
            targets = [x["output"] for x in plan if x["document_id"] in {"paper-a", "paper-b"}]
            self.assertEqual(len(set(targets)), 2)

    def test_edition_working_directory_is_resolved_and_passed_to_compiler(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            config["documents"]["paper-a"]["editions"]["en"]["working_directory"] = "papers"
            plan = plan_documents(root, config, "paper-a", "en")
            self.assertEqual(plan[0]["working_directory"], root / "papers")

            observed = {}

            def fake_latexmk(command, *, cwd, env, timeout):
                observed["cwd"] = Path(cwd)
                outdir = Path(next(arg.split("=", 1)[1] for arg in command if arg.startswith("-outdir=")))
                jobname = next(arg.split("=", 1)[1] for arg in command if arg.startswith("-jobname="))
                outdir.mkdir(parents=True, exist_ok=True)
                (outdir / f"{jobname}.pdf").write_bytes(b"%PDF-1.7\\nfixture\\n%%EOF\\n")

            with patch("px.project.run_checked", side_effect=fake_latexmk):
                build_documents(root, config, "paper-a", "en")
            self.assertEqual(observed["cwd"], root / "papers")
            import json
            manifest = json.loads((root / "build/manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(manifest["results"][0]["working_directory"], "papers")

    def test_working_directory_must_stay_inside_project_and_exist(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            edition = config["documents"]["paper-a"]["editions"]["en"]
            edition["working_directory"] = "../outside"
            with self.assertRaises(ConfigError):
                from px.config import validate_config
                validate_config(config)
            edition["working_directory"] = "missing"
            with self.assertRaises(BuildError):
                plan_documents(root, config, "paper-a", "en")

    def test_document_and_edition_selection(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            plan = plan_documents(root, config, "handbook", "fa")
            self.assertEqual([(x["document_id"], x["edition"]) for x in plan], [("handbook", "fa")])

    def test_v1_projects_keep_the_historical_output_layout(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "main.tex").write_text("fixture", encoding="utf-8")
            (root / "workspace.yml").write_text(
                """schema_version: 1
project:
  name: legacy-book
  type: book
  languages: [en]
build:
  output_dir: build
  entries:
    en: {source: main.tex, engine: pdflatex}
""",
                encoding="utf-8",
            )
            config = load_config(root)
            plan = plan_documents(root, config)
            self.assertEqual(plan[0]["output"].relative_to(root).as_posix(), "build/en/main.pdf")

    def test_v1_build_and_verify_keep_legacy_output_layout(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "main.tex").write_text("fixture", encoding="utf-8")
            (root / "workspace.yml").write_text(
                """schema_version: 1
project:
  name: legacy-book
  type: article
  languages: [en]
build:
  output_dir: build
  entries:
    en: {source: main.tex, engine: pdflatex}
""",
                encoding="utf-8",
            )
            config = load_config(root)

            def fake_latexmk(command, *, cwd, env, timeout):
                outdir = Path(next(arg.split("=", 1)[1] for arg in command if arg.startswith("-outdir=")))
                jobname = next(arg.split("=", 1)[1] for arg in command if arg.startswith("-jobname="))
                outdir.mkdir(parents=True, exist_ok=True)
                (outdir / f"{jobname}.pdf").write_bytes(b"%PDF-1.7\\nfixture\\n%%EOF\\n")

            with patch("px.project.run_checked", side_effect=fake_latexmk):
                build_documents(root, config, keep_going=True)
            self.assertTrue((root / "build/en/main.pdf").is_file())
            self.assertEqual(verify_manifest(root, config)["checked"], 1)

    def test_rejects_traversal(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)
            path = root / "workspace.yml"
            text = path.read_text(encoding="utf-8").replace("source: papers/a.tex", "source: ../escape.tex")
            path.write_text(text, encoding="utf-8")
            with self.assertRaises(ConfigError):
                load_config(root)

    def test_rejects_unsupported_engine(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)
            path = root / "workspace.yml"
            text = path.read_text(encoding="utf-8").replace("engine: pdflatex", "engine: tectonic")
            path.write_text(text, encoding="utf-8")
            with self.assertRaises(ConfigError):
                load_config(root)

    def test_rejects_symlink_source_escape(self):
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as outside:
            root = Path(tmp)
            self._project(root)
            outside_source = Path(outside) / "outside.tex"
            outside_source.write_text("fixture", encoding="utf-8")
            link = root / "papers" / "escape.tex"
            try:
                link.symlink_to(outside_source)
            except (OSError, NotImplementedError):
                self.skipTest("symlink creation is unavailable on this runner")
            config = load_config(root)
            config["documents"]["paper-a"]["editions"]["en"]["source"] = "papers/escape.tex"
            with self.assertRaises(BuildError):
                plan_documents(root, config)

    def test_partial_failures_are_recorded_and_return_nonzero(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)

            def partially_fail(command, *, cwd, env, timeout):
                source = Path(command[-1])
                if source.name == "a.tex":
                    raise RuntimeError("fixture compiler failure")
                outdir = Path(next(arg.split("=", 1)[1] for arg in command if arg.startswith("-outdir=")))
                jobname = next(arg.split("=", 1)[1] for arg in command if arg.startswith("-jobname="))
                outdir.mkdir(parents=True, exist_ok=True)
                (outdir / f"{jobname}.pdf").write_bytes(b"%PDF-1.7\\nfixture\\n%%EOF\\n")

            with patch("px.project.run_checked", side_effect=partially_fail):
                with self.assertRaises(BuildError):
                    build_documents(root, config, keep_going=True)
            import json
            manifest = json.loads((root / "build/manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(manifest["summary"]["failed"], 1)
            self.assertEqual(manifest["summary"]["completed"], 3)

    def test_partial_build_preserves_other_manifest_entries(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)

            def fake_latexmk(command, *, cwd, env, timeout):
                outdir = Path(next(arg.split("=", 1)[1] for arg in command if arg.startswith("-outdir=")))
                jobname = next(arg.split("=", 1)[1] for arg in command if arg.startswith("-jobname="))
                outdir.mkdir(parents=True, exist_ok=True)
                (outdir / f"{jobname}.pdf").write_bytes(b"%PDF-1.7\\nfixture\\n%%EOF\\n")

            with patch("px.project.run_checked", side_effect=fake_latexmk):
                build_documents(root, config, keep_going=True)
                build_documents(root, config, "paper-a", keep_going=True)
            self.assertEqual(verify_manifest(root, config)["checked"], 4)
            manifest = __import__("json").loads((root / "build/manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(len(manifest["results"]), 4)

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
            pdf = root / "build/paper-a/en/a.pdf"
            pdf.write_bytes(b"%PDF-1.7\ntampered\n%%EOF\n")
            with self.assertRaises(BuildError):
                verify_manifest(root, config)

            with patch("px.project.run_checked", side_effect=fake_latexmk):
                build_documents(root, config, keep_going=True)
            from px.project import clean_document
            clean_document(root, config, "handbook")
            self.assertTrue((root / "books/en.tex").is_file())
            remaining = list_documents(root, config)
            self.assertFalse(any(row["document_id"] == "handbook" and row["status"] == "success" for row in remaining))
            with self.assertRaises(BuildError):
                verify_manifest(root, config)

    def test_case_insensitive_artifact_collisions_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            first = config["documents"].pop("paper-a")
            second = config["documents"].pop("paper-b")
            first["editions"]["en"]["output_name"] = "shared"
            second["editions"]["en"]["output_name"] = "shared"
            config["documents"] = {"Paper": first, "paper": second}
            with self.assertRaisesRegex(BuildError, "case-insensitive filesystem"):
                plan_documents(root, config)

    def test_build_output_must_not_contain_configured_sources(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            config["build"]["output_dir"] = "papers"
            with self.assertRaisesRegex(BuildError, "contains a configured source file"):
                plan_documents(root, config)

    def test_clean_refuses_to_remove_source_directories(self):
        from px.build import clean_project

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = self._project(root)
            config["build"]["output_dir"] = "papers"
            with self.assertRaisesRegex(BuildError, "contains a configured source file"):
                clean_project(root, config)
            self.assertTrue((root / "papers/a.tex").is_file())

    def test_v2_documents_require_an_explicit_document_type(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)
            path = root / "workspace.yml"
            source = path.read_text(encoding="utf-8")
            source = source.replace("    type: article\n", "", 1)
            path.write_text(source, encoding="utf-8")
            with self.assertRaises(ConfigError):
                load_config(root)

    def test_article_style_is_rejected_for_non_article_documents(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)
            path = root / "workspace.yml"
            source = path.read_text(encoding="utf-8")
            source = source.replace(
                "  handbook:\n    type: book\n",
                "  handbook:\n    type: book\n    style: ieee\n",
                1,
            )
            path.write_text(source, encoding="utf-8")
            with self.assertRaises(ConfigError):
                load_config(root)


if __name__ == "__main__":
    unittest.main()
