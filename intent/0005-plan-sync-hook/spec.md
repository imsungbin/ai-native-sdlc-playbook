# Spec: plan-sync hook (from intent.md 2026-09-03)
Status: accepted.

## Requirements
- `.claude/hooks/plan-sync.sh`: PreToolUse on Bash. If the command contains
  "git commit", read the highest-numbered `intent/NNNN-*/plan.md`, take the
  paths under "## Files that change", compare with `git diff --cached
  --name-only`. Unplanned file staged and plan.md not staged: exit 2 and
  list the files.
- Tested in scripts/test_hooks.sh against a scratch repository.

## Design
Paths in the plan section are split on commas and newlines; "(new)" style
notes are stripped. Only tokens that look like paths count.

## Open questions from intent.md
None.

## Areas of concern
A plan that names directories rather than files will block. The message
says what to do.

## Skills applied
None.
