# Plan: the two build-time hooks (from intent.md 2026-09-03)

## Files that change
.claude/hooks/protect-tests.sh (new), .claude/hooks/protected-paths.sh (new),
.claude/protected-paths.txt (new), scripts/test_hooks.sh (new),
scripts/validate.sh

## Order of work
1. protect-tests.sh, probe by hand.
2. protected-paths.sh and the list file.
3. test_hooks.sh; validate.sh calls it.

## Risks
The verbatim settings.json cannot be edited to wire the new hooks, so in
this repository they run through the plugin (0008), and the tests exercise
them directly.

## Proof
`scripts/test_hooks.sh` ends with "all hook checks passed".
