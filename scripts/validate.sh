#!/bin/bash
# The single feedback-loop command for this repository (article Stage 4).
# Exits non-zero on any failure.
set -euo pipefail
cd "$(dirname "$0")/.."

FAILED=0

ok()   { echo "ok: $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }

PATHS=(
  README.md
  LICENSE
  CLAUDE.md
  REVIEW.md
  bands.yaml
  Makefile
  .gitignore
  .claude/settings.json
  .claude/hooks/production-gate.sh
  .claude/skills/secure-api-review/SKILL.md
  .claude/skills/intent-template/SKILL.md
  .claude/agents/verifier.md
  .claude/commands/spec.md
  .github/workflows/agent-evals.yml
  evals/check.sh
  evals/001-verification-command.json
  scripts/validate.sh
  templates/intent.md
  templates/spec.md
  templates/plan.md
  intent/0001-bootstrap-playbook-repo/intent.md
  intent/0001-bootstrap-playbook-repo/spec.md
  intent/0001-bootstrap-playbook-repo/plan.md
  intent/0002-multi-agent-entry-points/intent.md
  intent/0002-multi-agent-entry-points/spec.md
  intent/0002-multi-agent-entry-points/plan.md
  examples/article/README.md
  examples/article/intent.md
  examples/article/plan.md
  examples/article/CLAUDE.md
  examples/article/managed-settings.json
  examples/article/triage-step.yml
)

# a. every expected path exists and is non-empty
missing=0
for p in "${PATHS[@]}"; do
  if [ ! -s "$p" ]; then
    fail "missing or empty: $p"
    missing=1
  fi
done
[ "$missing" -eq 0 ] && ok "all ${#PATHS[@]} expected files exist and are non-empty"

# a2. entry points for other coding agents are links, not copies
LINKS=(
  "AGENTS.md:CLAUDE.md"
  ".agents/skills:../.claude/skills"
)
for pair in "${LINKS[@]}"; do
  link="${pair%%:*}"; want="${pair#*:}"
  if [ ! -L "$link" ]; then
    fail "not a symlink: $link (expected -> $want)"
  elif [ "$(readlink "$link")" != "$want" ]; then
    fail "symlink $link -> $(readlink "$link") (expected -> $want)"
  elif [ ! -e "$link" ]; then
    fail "symlink $link -> $want does not resolve"
  else
    ok "symlink $link -> $want"
  fi
done

# b. shell syntax and executable bit
SCRIPTS=(.claude/hooks/production-gate.sh evals/check.sh scripts/validate.sh)
for s in "${SCRIPTS[@]}"; do
  if [ ! -f "$s" ]; then
    fail "cannot syntax-check missing script: $s"
    continue
  fi
  if bash -n "$s" 2>/dev/null; then ok "bash -n $s"; else fail "bash -n $s"; fi
  if [ -x "$s" ]; then ok "executable: $s"; else fail "not executable: $s"; fi
done

# c. JSON parses
JSONS=(.claude/settings.json examples/article/managed-settings.json)
for j in evals/*.json; do [ -e "$j" ] && JSONS+=("$j"); done
for j in "${JSONS[@]}"; do
  if [ ! -f "$j" ]; then
    fail "cannot parse missing json: $j"
    continue
  fi
  if jq -e . "$j" >/dev/null 2>&1; then ok "jq parses $j"; else fail "jq parses $j"; fi
done
for e in evals/*.json; do
  [ -e "$e" ] || continue
  if jq -e '.prompt | type == "string"' "$e" >/dev/null 2>&1; then
    ok "eval has a string prompt: $e"
  else
    fail "eval has a string prompt: $e"
  fi
done

# d. YAML parses
yaml_parse() {
  if python3 -c 'import yaml' >/dev/null 2>&1; then
    python3 -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1]))' "$1"
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml -e 'YAML.load_file(ARGV[0])' "$1"
  else
    return 99
  fi
}
YAMLS=(bands.yaml .github/workflows/agent-evals.yml examples/article/triage-step.yml)
for y in "${YAMLS[@]}"; do
  if [ ! -f "$y" ]; then
    fail "cannot parse missing yaml: $y"
    continue
  fi
  rc=0
  yaml_parse "$y" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    ok "yaml parses $y"
  elif [ "$rc" -eq 99 ]; then
    echo "warning: no python3 yaml module and no ruby; skipped yaml parse of $y"
  else
    fail "yaml parses $y"
  fi
done

# e. the production gate behaves as the article defines it
GATE=.claude/hooks/production-gate.sh
gate_rc() {
  local payload="$1"
  local rc=0
  if [ -n "${2:-}" ]; then
    echo "$payload" | RELEASE_APPROVAL="$2" "$GATE" >/dev/null 2>&1 || rc=$?
  else
    echo "$payload" | env -u RELEASE_APPROVAL "$GATE" >/dev/null 2>&1 || rc=$?
  fi
  echo "$rc"
}
if [ -x "$GATE" ]; then
  DEPLOY='{"tool_input":{"command":"make deploy ENV=production"}}'
  SAFE='{"tool_input":{"command":"make test"}}'
  rc=$(gate_rc "$DEPLOY" "")
  if [ "$rc" -eq 2 ]; then ok "gate blocks production deploy without RELEASE_APPROVAL (exit 2)"
  else fail "gate blocks production deploy without RELEASE_APPROVAL (got exit $rc, want 2)"; fi
  rc=$(gate_rc "$DEPLOY" "ticket-123")
  if [ "$rc" -eq 0 ]; then ok "gate allows production deploy with RELEASE_APPROVAL (exit 0)"
  else fail "gate allows production deploy with RELEASE_APPROVAL (got exit $rc, want 0)"; fi
  rc=$(gate_rc "$SAFE" "")
  if [ "$rc" -eq 0 ]; then ok "gate allows an unrelated command (exit 0)"
  else fail "gate allows an unrelated command (got exit $rc, want 0)"; fi
else
  fail "production gate is missing or not executable: $GATE"
fi

# f. frontmatter on the skills and the agent
FRONTMATTER=(
  .claude/skills/secure-api-review/SKILL.md
  .claude/skills/intent-template/SKILL.md
  .claude/agents/verifier.md
)
for f in "${FRONTMATTER[@]}"; do
  if [ ! -f "$f" ]; then
    fail "cannot check frontmatter of missing file: $f"
    continue
  fi
  if [ "$(head -n 1 "$f")" = "---" ] && grep -q '^name:' "$f"; then
    ok "frontmatter with a name: line in $f"
  else
    fail "frontmatter with a name: line in $f"
  fi
done

# g. markdown documents start with a heading
MARKDOWN=(REVIEW.md CLAUDE.md templates/intent.md templates/spec.md templates/plan.md)
for m in "${MARKDOWN[@]}"; do
  if [ ! -s "$m" ]; then
    fail "cannot check heading of missing or empty file: $m"
    continue
  fi
  case "$(head -n 1 "$m")" in
    \#*) ok "starts with a heading: $m" ;;
    *)   fail "starts with a heading: $m" ;;
  esac
done

if [ "$FAILED" -ne 0 ]; then
  echo "validate: failures above"
  exit 1
fi
echo "validate: all checks passed"
