from __future__ import annotations

import unittest

from px.targets import resolve_target


class TargetProfileTests(unittest.TestCase):
    def test_devto_does_not_attach_a_csl_file(self) -> None:
        target = resolve_target("devto")
        self.assertIsNone(target["csl"])
        self.assertTrue(target["front_matter"])

    def test_medium_does_not_enable_citeproc(self) -> None:
        target = resolve_target("medium")
        self.assertIsNone(target["csl"])
        self.assertFalse(target["front_matter"])

    def test_ieee_uses_the_workspace_profile(self) -> None:
        self.assertEqual(resolve_target("ieee")["csl"], "ieee.csl")

    def test_project_yaml_overrides_a_builtin_profile(self) -> None:
        target = resolve_target("devto", {"devto": {"csl": "local.csl", "max_tags": 3}})
        self.assertEqual(target["csl"], "local.csl")
        self.assertEqual(target["max_tags"], 3)


if __name__ == "__main__":
    unittest.main()
