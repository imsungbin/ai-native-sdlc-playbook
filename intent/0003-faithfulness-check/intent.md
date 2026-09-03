# Intent: prove the verbatim layer is verbatim
Author: imsungbin (repo owner). Status: accepted.

## Problem
The README claims twelve files are copied from the article unchanged. The
claim is checked by a person reading a diff, which nobody does twice. One
file had already drifted (re-indented JSON) without anyone noticing.

## Proposed outcome
A test fails if any verbatim file changes by one byte. The repository also
has a PR check so branch protection can require it.

## Affected users and systems
Adopters relying on the "verbatim" label; scripts/validate.sh; the ruleset
on main.

## Constraints
No edits to the verbatim files themselves except restoring exact bytes.
The check runs offline. Detecting revisions to the article is a separate,
network-using script.

## Open questions
Whether the article's code blocks change over time. Unknown; a fingerprint
of them is recorded so drift is detectable.
