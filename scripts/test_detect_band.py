#!/usr/bin/env python3
"""Unit tests for scripts/detect-band.py (article Play 6a: "unit tested")."""
import importlib.util
import json
import os
import subprocess
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = importlib.util.spec_from_file_location("detect_band", os.path.join(HERE, "detect-band.py"))
db = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(db)

# Baseline: mean 10, population sigma 2, twenty samples alternating 8 and 12.
BASE = [8.0, 12.0] * 10


class Baseline(unittest.TestCase):
    def test_mean_and_sigma(self):
        mean, sigma, n = db.baseline(BASE, 30)
        self.assertEqual(n, 20)
        self.assertAlmostEqual(mean, 10.0)
        self.assertAlmostEqual(sigma, 2.0)

    def test_window_limits_baseline(self):
        mean, sigma, n = db.baseline([100.0] * 5 + BASE, 20)
        self.assertEqual(n, 20)
        self.assertAlmostEqual(mean, 10.0)


class Tiers(unittest.TestCase):
    def test_inside_one_sigma_is_none(self):
        r = db.classify(BASE + [10.5])
        self.assertEqual(r["tier"], "none")
        self.assertIsNone(r["rule"])

    def test_single_point_beyond_three_sigma_is_rule_one(self):
        r = db.classify(BASE + [17.0])
        self.assertEqual((r["tier"], r["rule"]), ("3sigma", 1))
        self.assertGreater(r["z"], 3)

    def test_single_point_beyond_two_sigma(self):
        r = db.classify(BASE + [14.5])
        self.assertEqual(r["tier"], "2sigma")

    def test_two_of_three_beyond_two_sigma_same_side_is_rule_two(self):
        r = db.classify(BASE + [14.5, 10.0, 14.5])
        self.assertEqual((r["tier"], r["rule"]), ("2sigma", 2))

    def test_two_of_three_on_opposite_sides_is_not_rule_two(self):
        r = db.classify(BASE + [14.5, 10.0, 5.5])
        self.assertNotEqual(r["rule"], 2)

    def test_four_of_five_beyond_one_sigma_is_rule_three(self):
        r = db.classify(BASE + [12.5, 12.5, 10.0, 12.5, 12.5])
        self.assertEqual((r["tier"], r["rule"]), ("1sigma", 3))

    def test_eight_on_one_side_is_rule_four(self):
        r = db.classify(BASE + [10.3] * 8)
        self.assertEqual((r["tier"], r["rule"]), ("1sigma", 4))

    def test_below_the_mean_counts_too(self):
        r = db.classify(BASE + [3.0])
        self.assertEqual((r["tier"], r["rule"]), ("3sigma", 1))
        self.assertLess(r["z"], -3)

    def test_flat_baseline_with_change_is_three_sigma(self):
        r = db.classify([5.0] * 10 + [6.0])
        self.assertEqual(r["tier"], "3sigma")

    def test_flat_baseline_without_change_is_none(self):
        r = db.classify([5.0] * 11)
        self.assertEqual(r["tier"], "none")

    def test_too_few_samples_is_none(self):
        self.assertEqual(db.classify([1.0])["tier"], "none")
        self.assertEqual(db.classify([])["tier"], "none")

    def test_deterministic(self):
        a = db.classify(BASE + [14.5, 10.0, 14.5])
        b = db.classify(BASE + [14.5, 10.0, 14.5])
        self.assertEqual(a, b)


class Inputs(unittest.TestCase):
    def test_json_list(self):
        self.assertEqual(db._values("[1, 2, 3.5]"), [1.0, 2.0, 3.5])

    def test_json_objects(self):
        self.assertEqual(db._values('[{"value": 1}, {"value": 2}]'), [1.0, 2.0])

    def test_lines(self):
        self.assertEqual(db._values("1\n2\n\n3\n"), [1.0, 2.0, 3.0])


class Cli(unittest.TestCase):
    def run_cli(self, payload, *extra):
        proc = subprocess.run(
            [sys.executable, os.path.join(HERE, "detect-band.py"), *extra],
            input=payload, capture_output=True, text=True, check=True)
        return json.loads(proc.stdout)

    def test_cli_reports_tier(self):
        out = self.run_cli(json.dumps(BASE + [17.0]))
        self.assertEqual(out["tier"], "3sigma")

    def test_cli_maps_action_from_bands_yaml(self):
        try:
            import yaml  # noqa: F401
        except ImportError:
            self.skipTest("PyYAML not installed")
        bands = os.path.join(HERE, "..", "bands.yaml")
        out = self.run_cli(json.dumps(BASE + [17.0]), "--bands", bands)
        self.assertEqual(out["action"], "propose")
        out = self.run_cli(json.dumps(BASE + [14.5]), "--bands", bands)
        self.assertEqual(out["action"], "diagnose")
        out = self.run_cli(json.dumps(BASE + [10.5]), "--bands", bands)
        self.assertIsNone(out["action"])


if __name__ == "__main__":
    unittest.main(verbosity=1)
