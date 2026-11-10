from __future__ import annotations

import unittest
from pathlib import Path

from px.resources import common_root, tex_inputs


class SharedTeXResourceTests(unittest.TestCase):
    def test_shared_components_and_presets_exist(self):
        shared = common_root()
        self.assertTrue((shared / "components" / "paper-styles.tex").is_file())
        self.assertTrue((shared / "presets" / "book" / "technical.tex").is_file())
        self.assertTrue((shared / "presets" / "article" / "academic.tex").is_file())
        self.assertTrue((shared / "packages" / "fonts.tex").is_file())

    def test_project_overrides_precede_shared_components(self):
        root = Path("/tmp/project")
        source = root / "papers" / "paper.tex"
        paths = tex_inputs(root, source).split(":")
        self.assertTrue(paths[0].startswith(str(source.parent)))
        self.assertTrue(paths[1].startswith(str(root / "tex")))
        self.assertTrue(paths[2].startswith(str(root / "configs")))
        self.assertTrue(paths[3].startswith(str(common_root())))
        self.assertTrue(paths[4].startswith(str(common_root() / "components")))


if __name__ == "__main__":
    unittest.main()
