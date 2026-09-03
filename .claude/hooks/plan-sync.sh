#!/bin/bash
# Completes article Play 3a, step 7: "When the implementation departs from the
# plan, update plan.md in the same commit; consider a hook that enforces the
# synchronization". Wire on PreToolUse with matcher "Bash".
#
# Acts only on commands containing "git commit". Reads the newest
# intent/<NNNN>-*/plan.md, takes the paths under "## Files that change", and
# blocks the commit if a staged file is outside that list while plan.md is not
# staged too. Files under intent/ and the plan itself are always allowed.
# No plan.md in the project: allow (the project is not using the loop yet).
cmd=$(jq -r '.tool_input.command // ""' < /dev/stdin)
case "$cmd" in *"git commit"*) ;; *) exit 0 ;; esac

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

plan=$(ls -d intent/[0-9][0-9][0-9][0-9]-*/plan.md 2>/dev/null | sort | tail -n 1)
[ -n "$plan" ] || exit 0

staged=$(git diff --cached --name-only)
[ -n "$staged" ] || exit 0

# Plan section -> one path per line. Strips "(new)" style notes and commas.
planned=$(awk '/^## Files that change/{f=1;next} /^## /{f=0} f' "$plan" \
  | tr ',' '\n' | sed -E 's/\([^)]*\)//g; s/^[[:space:]]+//; s/[[:space:]]+$//' \
  | grep -E '^[A-Za-z0-9_./-]+$' || true)

if echo "$staged" | grep -qx "$plan"; then exit 0; fi

off=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in intent/*) continue ;; esac
  if ! echo "$planned" | grep -qx "$f"; then off="$off  $f"$'\n'; fi
done <<< "$staged"

if [ -n "$off" ]; then
  echo "Staged files are not in '$plan' under '## Files that change':" >&2
  printf '%s' "$off" >&2
  echo "Update plan.md to match the diff and stage it in the same commit, or unstage the files." >&2
  exit 2
fi
exit 0
