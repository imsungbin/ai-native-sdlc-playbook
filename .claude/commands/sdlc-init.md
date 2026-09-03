---
description: Place the playbook's repo-root files into the current project without overwriting anything; append the verification block to CLAUDE.md behind markers.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/install/adopt.sh *), Bash(./install/adopt.sh *), Bash(git diff *), Bash(git status *), Read
---
Run the playbook installer against the current project and report what it did.

1. Locate the installer. If `${CLAUDE_PLUGIN_ROOT}` is set, it is
   `${CLAUDE_PLUGIN_ROOT}/install/adopt.sh`; otherwise it is `./install/adopt.sh`
   in this repository.
2. Run it: `<installer> --into . $ARGUMENTS` and capture its summary. The script
   is deterministic and idempotent. It creates files that are absent, never
   modifies a file that exists, and appends one marked block to CLAUDE.md. It
   does not commit.
3. Show `git status --short` and `git diff` so the person can see every change.
4. Repeat the installer's summary in four lists: created, appended, skipped
   (already present), and flagged (needs a decision). For every flagged item,
   say in one line what the person has to decide.
5. If the CLAUDE.md block contains `<your single test command>`, say so first;
   a wrong test command makes the verification block harmful.
6. Stop. Do not commit, do not run /init, do not edit CLAUDE.md by hand. The
   person reviews the diff and commits.
