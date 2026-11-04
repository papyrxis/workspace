from __future__ import annotations

import unittest

from px.tags import generate_tags


class TagTests(unittest.TestCase):
    def test_normalizes_deduplicates_and_limits_tags(self) -> None:
        self.assertEqual(
            generate_tags(["Data Science", "data-science", "Math", "C++", "unused"], 3),
            ["data-science", "math", "c"],
        )

    def test_skips_non_ascii_empty_values(self) -> None:
        self.assertEqual(generate_tags(["فارسی", "  ", "Python"]), ["python"])


if __name__ == "__main__":
    unittest.main()
