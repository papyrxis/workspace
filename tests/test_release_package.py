from __future__ import annotations

import tempfile
import unittest
import zipfile
from pathlib import Path

from scripts.package_release import build_bundle, verify_bundle


class ReleasePackageTests(unittest.TestCase):
    def test_bundle_is_deterministic_and_self_verifying(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            dist = root / "dist"
            dist.mkdir()
            (dist / "papyrxis_workspace-0.3.0-py3-none-any.whl").write_bytes(b"wheel fixture")
            (dist / "papyrxis_workspace-0.3.0.tar.gz").write_bytes(b"sdist fixture")
            first = build_bundle(dist, root / "one.zip")
            first_bytes = first.read_bytes()
            second = build_bundle(dist, root / "two.zip")
            self.assertEqual(first_bytes, second.read_bytes())
            self.assertEqual(verify_bundle(first)["verified"], 2)

    def test_bundle_rejects_tampered_payload(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            dist = root / "dist"
            dist.mkdir()
            (dist / "pkg.whl").write_bytes(b"wheel")
            (dist / "pkg.tar.gz").write_bytes(b"sdist")
            bundle = build_bundle(dist, root / "bundle.zip")
            with zipfile.ZipFile(bundle, "a") as archive:
                archive.writestr("dist/pkg.whl", b"tampered")
            with self.assertRaises(ValueError):
                verify_bundle(bundle)


if __name__ == "__main__":
    unittest.main()
