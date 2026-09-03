# Spec: review loop completion (from intent.md 2026-09-03)
Status: accepted.

## Requirements
- `scripts/check-endpoints.sh [dir]`: lists route declarations across
  common frameworks as file:line, or says none were found. Exit 0.
- `.claude/commands/babysit-pr.md`: loops over failing checks and
  unresolved review threads, at most six rounds, pushes to the PR branch,
  never merges, never force-pushes, never edits tests.
- `evals/002-secure-api-skill-triggers.json` and
  `evals/003-intent-template-format.json` with result_contains checks.

## Design
Prompts only for the command; the deterministic parts are gh calls it is
allowed to make.

## Open questions from intent.md
None.

## Areas of concern
Evals run only with a funded key.

## Skills applied
None.
