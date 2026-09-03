# Plan: review loop completion (from intent.md 2026-09-03)

## Files that change
scripts/check-endpoints.sh (new), .claude/commands/babysit-pr.md (new),
evals/002-secure-api-skill-triggers.json (new),
evals/003-intent-template-format.json (new), scripts/validate.sh

## Order of work
1. check-endpoints.sh; run it here (no endpoints) and on a sample.
2. babysit-pr.md.
3. The two evals.

## Risks
Eval expectations that are too literal fail on wording; they check
distinctive tokens only.

## Proof
`scripts/check-endpoints.sh .` prints the no-endpoints line. validate.sh
parses both evals and finds a string prompt.
