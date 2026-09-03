#!/bin/bash
# The single feedback-loop command for this repository (article Stage 4).
# Exits non-zero on any failure. Structural checks first, then the verbatim
# hash lock, then the behavior tests for hooks, installer and detector.
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
  verbatim.lock
  .claude/settings.json
  .claude/protected-paths.txt
  .claude/hooks/production-gate.sh
  .claude/hooks/plan-sync.sh
  .claude/hooks/protect-tests.sh
  .claude/hooks/protected-paths.sh
  .claude/hooks/hooks.json
  .claude/skills/secure-api-review/SKILL.md
  .claude/skills/intent-template/SKILL.md
  .claude/agents/verifier.md
  .claude/commands/spec.md
  .claude/commands/sdlc-init.md
  .claude/commands/babysit-pr.md
  .claude-plugin/plugin.json
  .claude-plugin/marketplace.json
  .github/workflows/agent-evals.yml
  .github/workflows/test.yml
  .github/workflows/bands.yml
  evals/check.sh
  evals/001-verification-command.json
  evals/002-secure-api-skill-triggers.json
  evals/003-intent-template-format.json
  install/adopt.sh
  install/MANIFEST
  install/protected-paths.template.txt
  scripts/validate.sh
  scripts/check-verbatim.sh
  scripts/check-article.sh
  scripts/check-endpoints.sh
  scripts/detect-band.py
  scripts/test_detect_band.py
  scripts/test_hooks.sh
  scripts/test_adopt.sh
  templates/intent.md
  templates/spec.md
  templates/plan.md
  templates/CLAUDE.md
  templates/REVIEW.md
  docs/article-map.md
  docs/article-blocks.sha256
  examples/article/README.md
  examples/article/intent.md
  examples/article/plan.md
  examples/article/CLAUDE.md
  examples/article/managed-settings.json
  examples/article/triage-step.yml
)
for n in 0001-bootstrap-playbook-repo 0002-multi-agent-entry-points \
         0003-faithfulness-check 0004-build-time-hooks 0005-plan-sync-hook \
         0006-band-detection 0007-review-loop-completion 0008-plugin-and-installer; do
  PATHS+=("intent/$n/intent.md" "intent/$n/spec.md" "intent/$n/plan.md")
done

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
SCRIPTS=(
  .claude/hooks/production-gate.sh
  .claude/hooks/plan-sync.sh
  .claude/hooks/protect-tests.sh
  .claude/hooks/protected-paths.sh
  evals/check.sh
  install/adopt.sh
  scripts/validate.sh
  scripts/check-verbatim.sh
  scripts/check-article.sh
  scripts/check-endpoints.sh
  scripts/test_hooks.sh
  scripts/test_adopt.sh
)
for s in "${SCRIPTS[@]}"; do
  if [ ! -f "$s" ]; then
    fail "cannot syntax-check missing script: $s"
    continue
  fi
  if bash -n "$s" 2>/dev/null; then ok "bash -n $s"; else fail "bash -n $s"; fi
  if [ -x "$s" ]; then ok "executable: $s"; else fail "not executable: $s"; fi
done
for py in scripts/detect-band.py scripts/test_detect_band.py; do
  if python3 -m py_compile "$py" 2>/dev/null; then ok "py_compile $py"; else fail "py_compile $py"; fi
done

# c. JSON parses
JSONS=(
  .claude/settings.json
  .claude/hooks/hooks.json
  .claude-plugin/plugin.json
  .claude-plugin/marketplace.json
  examples/article/managed-settings.json
)
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

# c2. plugin manifests agree with each other and point at real paths
pv=$(jq -r .version .claude-plugin/plugin.json 2>/dev/null || echo "?")
mv=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json 2>/dev/null || echo "?")
pn=$(jq -r .name .claude-plugin/plugin.json 2>/dev/null || echo "?")
mn=$(jq -r '.plugins[0].name' .claude-plugin/marketplace.json 2>/dev/null || echo "?")
if [ "$pv" = "$mv" ] && [ "$pn" = "$mn" ]; then ok "plugin.json and marketplace.json agree ($pn $pv)"
else fail "plugin.json ($pn $pv) and marketplace.json ($mn $mv) disagree"; fi
for key in commands agents skills hooks; do
  p=$(jq -r ".$key" .claude-plugin/plugin.json 2>/dev/null)
  if [ -e "$p" ]; then ok "plugin.json $key -> $p exists"; else fail "plugin.json $key -> $p missing"; fi
done
while read -r cmd; do
  f="${cmd#\$\{CLAUDE_PLUGIN_ROOT\}/}"
  if [ -x "$f" ]; then ok "hooks.json wires executable $f"; else fail "hooks.json wires missing or non-executable $f"; fi
done < <(jq -r '.. | objects | select(has("command")) | .command' .claude/hooks/hooks.json)

# c3. the install manifest names files that exist
while IFS=$'\t' read -r mode layer src dst; do
  case "$mode" in ''|\#*) continue ;; esac
  if [ -f "$src" ]; then ok "MANIFEST $layer $src"; else fail "MANIFEST source missing: $src"; fi
done < install/MANIFEST

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
YAMLS=(
  bands.yaml
  .github/workflows/agent-evals.yml
  .github/workflows/test.yml
  .github/workflows/bands.yml
  examples/article/triage-step.yml
)
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

# f. frontmatter on the skills, the agent and the commands
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
for f in .claude/commands/sdlc-init.md .claude/commands/babysit-pr.md; do
  if [ "$(head -n 1 "$f")" = "---" ] && grep -q '^description:' "$f"; then
    ok "frontmatter with a description: line in $f"
  else
    fail "frontmatter with a description: line in $f"
  fi
done

# g. markdown documents start with a heading
MARKDOWN=(
  REVIEW.md CLAUDE.md docs/article-map.md
  templates/intent.md templates/spec.md templates/plan.md
  templates/CLAUDE.md templates/REVIEW.md
)
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

# g2. CLAUDE.md stays within the article's one-page rule
lines=$(wc -l < CLAUDE.md | tr -d ' ')
if [ "$lines" -le 60 ]; then ok "CLAUDE.md is $lines lines (one page)"; else fail "CLAUDE.md is $lines lines; the article asks for one page"; fi

# h. the verbatim layer is byte-identical to the lock
if bash scripts/check-verbatim.sh; then ok "verbatim layer matches verbatim.lock"; else fail "verbatim layer does not match verbatim.lock"; fi

# h2. every locked file is also a protected path for sessions
while read -r _ path; do
  [ -n "$path" ] || continue
  rc=0
  printf '{"tool_input":{"file_path":"%s/%s"}}' "$(pwd)" "$path" \
    | CLAUDE_PROJECT_DIR="$(pwd)" .claude/hooks/protected-paths.sh >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 2 ]; then ok "protected path: $path"; else fail "verbatim file is not a protected path: $path"; fi
done < verbatim.lock

# i. behavior tests
if bash scripts/test_hooks.sh; then ok "hook behavior tests"; else fail "hook behavior tests"; fi
if bash scripts/test_adopt.sh; then ok "installer behavior tests"; else fail "installer behavior tests"; fi
if python3 scripts/test_detect_band.py >/dev/null 2>&1; then ok "detect-band unit tests"; else fail "detect-band unit tests"; python3 scripts/test_detect_band.py 2>&1 | tail -5; fi

if [ "$FAILED" -ne 0 ]; then
  echo "validate: failures above"
  exit 1
fi
echo "validate: all checks passed"
