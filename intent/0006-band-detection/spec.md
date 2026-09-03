# Spec: band detection (from intent.md 2026-09-03)
Status: accepted.

## Requirements
- `scripts/detect-band.py`: input JSON or lines, oldest first; last sample
  is the observation; rolling window default 30. Rules 1 to 4 of Western
  Electric. Output JSON with tier, rule, z, mean, sigma, n, action.
- `scripts/test_detect_band.py`: unittest, run by make test.
- `.github/workflows/bands.yml`: nightly; computes daily failure share of
  workflow runs over 30 days; runs the script; diagnose job at 2sigma or
  above with the tools string from bands.yaml; propose job at 3sigma
  writes an intent through the intent-template skill and opens a PR.

## Design
Population sigma over the window. Tier names match bands.yaml keys so the
mapping is a lookup, not logic.

## Open questions from intent.md
- Daily buckets: kept.

## Areas of concern
The propose job needs contents and pull-requests write permission; scoped
in the workflow, not the repository.

## Skills applied
intent-template (in the workflow's propose step).
