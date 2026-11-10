from __future__ import annotations

import unittest

from scripts.set_release_version import pep440_version


class ReleaseVersionTests(unittest.TestCase):
    def test_stable_and_prerelease_tags_map_to_pep440(self):
        self.assertEqual(pep440_version("v1.2.3"), "1.2.3")
        self.assertEqual(pep440_version("v1.2.3-alpha.1"), "1.2.3a1")
        self.assertEqual(pep440_version("v1.2.3-beta.4"), "1.2.3b4")
        self.assertEqual(pep440_version("v1.2.3-rc.2"), "1.2.3rc2")
        self.assertEqual(pep440_version("v0.0.0-dev.abcdef0"), "0.0.0.dev11259360")

    def test_rejects_non_semver_tag(self):
        with self.assertRaises(ValueError):
            pep440_version("latest")


if __name__ == "__main__":
    unittest.main()
