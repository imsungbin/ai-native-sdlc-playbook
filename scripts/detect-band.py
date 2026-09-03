#!/usr/bin/env python3
"""Completes article Play 6a, step 2: the deterministic detection script.

"Write a detection script (mean and standard deviation on a rolling window,
with rules like Western Electric); version controlled, unit tested; detection
entirely deterministic, no model." This file is that script. No model, no
network, standard library only.

Input: a series of metric samples, oldest first, as JSON (a list of numbers or
a list of {"value": n} objects) or as one number per line. The last sample is
the observation under test; the samples before it form the rolling baseline.

Output: one JSON object on stdout:
  {"tier": "none|1sigma|2sigma|3sigma", "rule": <int or null>, "z": <float>,
   "mean": <float>, "sigma": <float>, "n": <int>, "action": <str or null>}
"action" is filled when --bands points at a bands.yaml and PyYAML is present.

Western Electric rules, evaluated on the most recent points:
  1: one point beyond 3 sigma                     -> 3sigma
  2: two of the last three beyond 2 sigma, same side -> 2sigma
  3: four of the last five beyond 1 sigma, same side -> 1sigma
  4: eight consecutive points on one side of the mean -> 1sigma
Rule 1 wins over 2 wins over 3 wins over 4. A single point beyond 2 sigma
with no rule triggered reports 2sigma; beyond 1 sigma reports 1sigma. That
keeps the tier names in bands.yaml meaningful for one-off spikes as well as
for runs.
"""
import argparse
import json
import math
import sys


def _values(raw):
    raw = raw.strip()
    if not raw:
        return []
    if raw[0] in "[{":
        data = json.loads(raw)
        if isinstance(data, dict):
            data = data.get("values", [])
        out = []
        for item in data:
            out.append(float(item["value"] if isinstance(item, dict) else item))
        return out
    return [float(line) for line in raw.splitlines() if line.strip()]


def baseline(samples, window):
    """Mean and population sigma of the last `window` samples."""
    base = samples[-window:] if window and window > 0 else samples
    n = len(base)
    if n == 0:
        return 0.0, 0.0, 0
    mean = sum(base) / n
    var = sum((x - mean) ** 2 for x in base) / n
    return mean, math.sqrt(var), n


def side(x, mean):
    return 1 if x > mean else (-1 if x < mean else 0)


def classify(samples, window=30):
    """Return the detection result for the last sample against the rest."""
    if len(samples) < 2:
        return {"tier": "none", "rule": None, "z": 0.0, "mean": 0.0,
                "sigma": 0.0, "n": len(samples)}
    history, current = samples[:-1], samples[-1]
    mean, sigma, n = baseline(history, window)
    if sigma == 0.0:
        z = 0.0 if current == mean else math.inf * side(current, mean)
    else:
        z = (current - mean) / sigma
    recent = samples[-8:]

    def beyond(k, pts):
        return [p for p in pts if sigma > 0 and abs(p - mean) > k * sigma]

    def same_side(pts):
        s = {side(p, mean) for p in pts}
        return len(s) == 1 and 0 not in s

    tier, rule = "none", None
    if sigma == 0.0 and current != mean:
        tier, rule = "3sigma", 1
    elif abs(z) > 3:
        tier, rule = "3sigma", 1
    else:
        last3 = samples[-3:]
        b2 = beyond(2, last3)
        last5 = samples[-5:]
        b1 = beyond(1, last5)
        if len(last3) == 3 and len(b2) >= 2 and same_side(b2):
            tier, rule = "2sigma", 2
        elif len(last5) == 5 and len(b1) >= 4 and same_side(b1):
            tier, rule = "1sigma", 3
        elif len(recent) == 8 and same_side(recent):
            tier, rule = "1sigma", 4
        elif abs(z) > 2:
            tier = "2sigma"
        elif abs(z) > 1:
            tier = "1sigma"
    return {"tier": tier, "rule": rule,
            "z": (z if math.isfinite(z) else (1e9 if z > 0 else -1e9)),
            "mean": mean, "sigma": sigma, "n": n}


def action_for(tier, bands_path):
    if tier == "none" or not bands_path:
        return None
    try:
        import yaml  # type: ignore
    except ImportError:
        return None
    with open(bands_path) as fh:
        bands = yaml.safe_load(fh) or {}
    tiers = bands.get("tiers", {})
    entry = tiers.get(tier) or {}
    return entry.get("action")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--input", "-i", default="-", help="file or - for stdin")
    ap.add_argument("--window", "-w", type=int, default=30,
                    help="rolling baseline size in samples (default 30)")
    ap.add_argument("--bands", "-b", default=None,
                    help="bands.yaml to map the tier to an action")
    args = ap.parse_args(argv)
    raw = sys.stdin.read() if args.input == "-" else open(args.input).read()
    samples = _values(raw)
    result = classify(samples, args.window)
    result["action"] = action_for(result["tier"], args.bands)
    json.dump(result, sys.stdout)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
