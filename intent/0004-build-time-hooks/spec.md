# Spec: the two build-time hooks (from intent.md 2026-09-03)
Status: accepted.

## Requirements
- `.claude/hooks/protect-tests.sh`: PreToolUse on Edit, Write, MultiEdit.
  When SDLC_FIX_TASK is set and the path looks like a test file, exit 2.
- `.claude/hooks/protected-paths.sh`: same event. Reads
  `.claude/protected-paths.txt` (shell globs, one per line, # comments).
  A match exits 2. No file means allow.
- `.claude/protected-paths.txt` in this repository lists the verbatim
  layer.
- `scripts/test_hooks.sh` exercises both with the JSON a hook receives.

## Design
bash and jq only, matching production-gate.sh. Messages say what was
blocked and who changes it.

## Open questions from intent.md
- Configurable test patterns: carried forward.

## Areas of concern
None.

## Skills applied
None.
