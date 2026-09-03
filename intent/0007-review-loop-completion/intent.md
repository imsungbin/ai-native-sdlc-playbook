# Intent: the pieces of Stages 3e and 5a the article leaves in prose
Author: imsungbin (repo owner). Status: accepted.

## Problem
The security skill ends by running scripts/check-endpoints.sh, which did
not exist, so the skill failed at its last step. Play 5a step 4 describes
a slash command that babysits a PR to green; none shipped. Play 3e step 4
says to test that skills trigger; no eval did.

## Proposed outcome
The script exists and is honest about what it checks. The command exists.
Two evals prove the skills load.

## Affected users and systems
Adopters using the skill; the evals workflow.

## Constraints
The article does not say what check-endpoints.sh checks, so it inventories
endpoint declarations for the reviewer and leaves the judgement to the
skill. The babysit command never merges and never edits tests.

## Open questions
None.
