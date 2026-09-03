# Intent: a hook that keeps plan.md in step with the diff
Author: imsungbin (repo owner). Status: accepted.

## Problem
Article Play 3a step 7: when the implementation departs from the plan,
update plan.md in the same commit, and consider a hook that enforces it.
Without the hook the lagging measure, "how often the merged diff still
matches plan.md", is measured by nobody.

## Proposed outcome
A commit that stages a file the current plan does not name is blocked
unless plan.md is staged with it.

## Affected users and systems
Sessions committing in a repository that uses intent/ directories.

## Constraints
Acts only on git commit commands. Files under intent/ are always allowed.
No plan.md at all means allow.

## Open questions
None.
