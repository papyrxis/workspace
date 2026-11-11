from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from px.cli import main
from px.config import load_config


class CollectionInitTests(unittest.TestCase):
    def test_init_collection_creates_schema_v2_with_bilingual_first_document(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "my-library"
            self.assertEqual(main(["--root", str(root), "init", "--type", "collection", "--language", "both"]), 0)
            config = load_config(root)
            self.assertEqual(config["schema_version"], 2)
            self.assertEqual(config["project"]["type"], "collection")
            self.assertEqual(config["documents"]["first-article"]["style"], "personal")
            editions = config["documents"]["first-article"]["editions"]
            self.assertEqual(set(editions), {"en", "fa"})
            self.assertTrue((root / editions["en"]["source"]).is_file())
            self.assertTrue((root / editions["fa"]["source"]).is_file())

    def test_article_init_creates_selected_style_abstract_sections_and_bibliography(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "my-paper"
            self.assertEqual(main([
                "--root", str(root), "init", "--type", "article", "--style", "ieee", "--language", "en"
            ]), 0)
            config = load_config(root)
            self.assertEqual(config["project"]["style"], "ieee")
            source = (root / "main.tex").read_text(encoding="utf-8")
            self.assertIn(r"\begin{abstract}", source)
            self.assertIn(r"\keywords{", source)
            self.assertIn(r"\bibliographystyle{IEEEtran}", source)
            self.assertIn("sections/01-introduction", source)
            self.assertTrue((root / "sections/02-approach.tex").is_file())
            self.assertTrue((root / "references/references.bib").is_file())

    def test_book_and_booklet_init_create_profile_specific_structures(self):
        for kind in ("book", "booklet"):
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp) / f"my-{kind}"
                self.assertEqual(main(["--root", str(root), "init", "--type", kind]), 0)
                config = load_config(root)
                self.assertEqual(config["project"]["type"], kind)
                source = (root / "main.tex").read_text(encoding="utf-8")
                self.assertIn(r"\frontmatter", source)
                self.assertTrue((root / "chapters/chapter-01.tex").is_file())
                self.assertTrue((root / "frontmatter/preface.tex").is_file())
                self.assertTrue((root / "references/references.bib").is_file())
                if kind == "book":
                    self.assertIn(r"\include{parts/part-01}", source)
                    part = (root / "parts/part-01.tex").read_text(encoding="utf-8")
                    self.assertIn(r"\input{chapters/chapter-01}", part)
                    self.assertIn(r"\printindex", source)
                    self.assertTrue((root / "backmatter/appendix.tex").is_file())
                else:
                    self.assertIn(r"\include{chapters/chapter-01}", source)
                    self.assertIn(r"\geometry{a5paper", source)
                    self.assertTrue((root / "backmatter/notes.tex").is_file())

    def test_style_option_is_rejected_for_non_article_profiles(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "invalid-style"
            self.assertEqual(main([
                "--root", str(root), "init", "--type", "book", "--style", "ieee"
            ]), 1)


if __name__ == "__main__":
    unittest.main()
