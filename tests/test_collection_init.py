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
            editions = config["documents"]["first-article"]["editions"]
            self.assertEqual(set(editions), {"en", "fa"})
            self.assertTrue((root / editions["en"]["source"]).is_file())
            self.assertTrue((root / editions["fa"]["source"]).is_file())


if __name__ == "__main__":
    unittest.main()
