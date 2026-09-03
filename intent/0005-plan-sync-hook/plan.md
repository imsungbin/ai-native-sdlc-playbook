# Plan: plan-sync hook (from intent.md 2026-09-03)

## Files that change
.claude/hooks/plan-sync.sh (new), scripts/test_hooks.sh

## Order of work
1. plan-sync.sh.
2. Five cases in test_hooks.sh: not a commit, unplanned file, plan staged
   too, planned file, no plan.

## Risks
Slow git commands on every Bash call; avoided by returning before any git
call unless the command is a commit.

## Proof
test_hooks.sh prints five plan-sync lines, all ok.
