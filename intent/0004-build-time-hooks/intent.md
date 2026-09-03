# Intent: the two build-time hooks the article describes in prose
Author: imsungbin (repo owner). Status: accepted.

## Problem
Article Play 3f and Stage 4 step 7 describe hooks that block edits to
protected paths and block test-file edits during a fix task. The article
prints neither. Adopters are told to write their own, so most do not.

## Proposed outcome
Both hooks exist, are small, are tested, and explain themselves when they
block. This repository uses the protected-paths hook on its own verbatim
layer.

## Affected users and systems
Sessions in this repository and in adopters' repositories; validate.sh.

## Constraints
A fix task is declared, not guessed: SDLC_FIX_TASK=1 in the environment.
Patterns for protected paths come from a file the adopter owns. Hooks
exit 2 with a reason on stderr, as the article's gate does.

## Open questions
Whether test-file detection should be configurable. Not for now; the
patterns cover the common layouts.
