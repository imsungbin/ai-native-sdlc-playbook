#!/bin/bash
# The faithfulness guarantee. Every file in the verbatim layer has a sha256
# in verbatim.lock; this script fails if any of them changed by one byte.
#   scripts/check-verbatim.sh           verify
#   scripts/check-verbatim.sh --update  rewrite verbatim.lock (maintainers,
#                                       only after re-checking the article)
set -euo pipefail
cd "$(dirname "$0")/.."
LOCK=verbatim.lock

sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

VERBATIM=(
  REVIEW.md
  bands.yaml
  .claude/settings.json
  .claude/hooks/production-gate.sh
  .claude/skills/secure-api-review/SKILL.md
  .claude/agents/verifier.md
  .github/workflows/agent-evals.yml
  examples/article/intent.md
  examples/article/plan.md
  examples/article/CLAUDE.md
  examples/article/managed-settings.json
  examples/article/triage-step.yml
)

if [ "${1:-}" = "--update" ]; then
  : > "$LOCK"
  for f in "${VERBATIM[@]}"; do printf '%s  %s\n' "$(sha "$f")" "$f" >> "$LOCK"; done
  echo "check-verbatim: wrote ${#VERBATIM[@]} entries to $LOCK"
  exit 0
fi

[ -f "$LOCK" ] || { echo "FAIL: $LOCK missing; run scripts/check-verbatim.sh --update" >&2; exit 1; }
rc=0
while read -r want path; do
  [ -n "$path" ] || continue
  if [ ! -f "$path" ]; then echo "FAIL: verbatim file missing: $path"; rc=1; continue; fi
  have=$(sha "$path")
  if [ "$have" = "$want" ]; then echo "ok: verbatim $path"
  else echo "FAIL: verbatim file changed: $path"; rc=1; fi
done < "$LOCK"
n=$(grep -c . "$LOCK")
if [ "$n" -ne "${#VERBATIM[@]}" ]; then
  echo "FAIL: $LOCK has $n entries, expected ${#VERBATIM[@]}"; rc=1
fi
exit $rc
