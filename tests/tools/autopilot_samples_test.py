"""Checks of tools/example.py's comparison of the autopilot's samples between the browser and a native run: alike within a sample's
tolerance per channel (3 when it gives none), and each way they can differ (a channel too far apart, another number of points, a sample on
one side only) named."""
import argparse
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
argparse.ArgumentParser(description=__doc__).parse_args()
from example import compare_samples


def sample(*colors, tolerance=None):
    """A published sample of these colors at made-up points."""
    record = {'points': [[i, i] for i in range(len(colors))], 'colors': [list(c) for c in colors]}
    if tolerance is not None:
        record['tolerance'] = tolerance
    return record


class CompareSamplesTests(unittest.TestCase):
    def test_alike_within_tolerance(self):
        self.assertEqual(compare_samples({'a': sample((10, 20, 30, 255), tolerance=3)}, {'a': sample((13, 17, 30, 255), tolerance=3)}), [])
        self.assertEqual(compare_samples({}, {}), [])

    def test_default_tolerance_is_three(self):
        self.assertEqual(compare_samples({'a': sample((0, 0, 0, 0))}, {'a': sample((3, 0, 0, 0))}), [])
        self.assertEqual(len(compare_samples({'a': sample((0, 0, 0, 0))}, {'a': sample((0, 0, 0, 4))})), 1)

    def test_a_larger_tolerance(self):
        self.assertEqual(compare_samples({'bloom': sample((100, 0, 0, 255), tolerance=12)}, {'bloom': sample((112, 0, 0, 255), tolerance=12)}), [])

    def test_too_far_apart_named(self):
        problems = compare_samples({'a': sample((0, 0, 0, 255), (50, 50, 50, 255))}, {'a': sample((0, 0, 0, 255), (50, 60, 50, 255))})
        self.assertEqual(len(problems), 1)
        self.assertIn('a point 1', problems[0])
        self.assertIn('10 apart', problems[0])

    def test_points_and_names_must_match(self):
        self.assertEqual(len(compare_samples({'a': sample((0, 0, 0, 0))}, {'a': sample((0, 0, 0, 0), (0, 0, 0, 0))})), 1)
        problems = compare_samples({'a': sample((0, 0, 0, 0))}, {'b': sample((0, 0, 0, 0))})
        self.assertEqual(problems, ['a: only in the browser', 'b: only in the native run'])


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]], verbosity=2)
