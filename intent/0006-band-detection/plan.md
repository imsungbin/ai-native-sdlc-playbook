# Plan: band detection (from intent.md 2026-09-03)

## Files that change
scripts/detect-band.py (new), scripts/test_detect_band.py (new),
.github/workflows/bands.yml (new), scripts/validate.sh

## Order of work
1. detect-band.py with the four rules.
2. Tests for each rule, both sides of the mean, flat baseline, inputs, CLI,
   bands.yaml mapping.
3. bands.yml with the three jobs.

## Risks
Few samples early on: the script returns none below two samples and the
workflow reports the sample count.

## Proof
`python3 scripts/test_detect_band.py` passes. A series with a 3.5 sigma
spike and --bands bands.yaml prints action "propose".
