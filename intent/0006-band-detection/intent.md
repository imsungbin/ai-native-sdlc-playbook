# Intent: the deterministic detection script behind bands.yaml
Author: imsungbin (repo owner). Status: accepted.

## Problem
bands.yaml names tiers and actions but nothing computes a tier. Article
Play 6a step 2 says the detection script is deterministic, rolling mean
and standard deviation, Western Electric rules, unit tested, no model.
The repository shipped the config without the thing it configures.

## Proposed outcome
A script reads a metric series, reports the tier and the action from
bands.yaml, and a scheduled workflow runs it against this repository's
own CI failure rate. Claude steps run only at the tiers the config allows
and only when a key is present.

## Affected users and systems
This repository's Actions; adopters who copy the script.

## Constraints
Standard library only. The workflow must be honest without a key: detect
always, diagnose and propose skipped with a visible reason.

## Open questions
Whether daily buckets are the right sample. A rolling 30-day window of
daily rates matches "baseline: rolling_30d".
