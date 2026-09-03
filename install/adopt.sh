#!/bin/bash
# Places the playbook into a target project. Deterministic and idempotent.
#
#   install/adopt.sh --into DIR [--plugin|--standalone] [--dry-run]
#
# Rules, in order of importance:
#   1. A file that exists is never modified. It is reported as skipped.
#   2. CLAUDE.md gets exactly one marked block appended (the verification
#      block). Everything outside the markers is never touched.
#   3. Nothing is committed. The person reads the diff.
#
# --plugin     the ai-native-sdlc plugin provides skills, agent, commands and
#              hooks; only repo-root files are placed. Default when
#              CLAUDE_PLUGIN_ROOT is set.
# --standalone also copies .claude/ components and merges hook wiring into
#              .claude/settings.json. Default otherwise.
set -o pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=""; MODE=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --into) TARGET="$2"; shift 2 ;;
    --plugin) MODE=plugin; shift ;;
    --standalone) MODE=standalone; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "adopt: unknown argument: $1" >&2; exit 1 ;;
  esac
done
[ -n "$TARGET" ] || { echo "adopt: --into DIR is required" >&2; exit 1; }
[ -d "$TARGET" ] || { echo "adopt: not a directory: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
[ -n "$MODE" ] || { if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then MODE=plugin; else MODE=standalone; fi; }
VERSION=$(jq -r .version "$SRC/.claude-plugin/plugin.json")

CREATED=(); APPENDED=(); SKIPPED=(); FLAGGED=()
say() { echo "adopt: $*"; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1; else shasum -a 256 | cut -d' ' -f1; fi; }

place() { # src dest
  local s="$SRC/$1" d="$TARGET/$2"
  if [ -e "$d" ]; then SKIPPED+=("$2"); return; fi
  if [ "$DRY" -eq 0 ]; then mkdir -p "$(dirname "$d")"; cp "$s" "$d"; fi
  CREATED+=("$2")
}

# 1. Files from the manifest -------------------------------------------------
while IFS=$'\t' read -r mode layer src dst; do
  case "$mode" in ''|\#*) continue ;; esac
  [ "$mode" = both ] || [ "$mode" = "$MODE" ] || continue
  place "$src" "$dst"
done < "$SRC/install/MANIFEST"

# 2. Hook wiring (standalone only): merge into .claude/settings.json ----------
if [ "$MODE" = standalone ]; then
  settings="$TARGET/.claude/settings.json"
  wanted=$(sed 's|${CLAUDE_PLUGIN_ROOT}|${CLAUDE_PROJECT_DIR}|g' "$SRC/.claude/hooks/hooks.json")
  if [ ! -e "$settings" ]; then
    if [ "$DRY" -eq 0 ]; then mkdir -p "$TARGET/.claude"; printf '%s\n' "$wanted" > "$settings"; fi
    CREATED+=(".claude/settings.json")
  elif jq -e . "$settings" >/dev/null 2>&1; then
    merged=$(jq --argjson add "$wanted" '
      def cmds: [.. | objects | select(has("command")) | .command];
      . as $cur | ($cur | cmds) as $have
      | reduce ($add.hooks.PreToolUse[]) as $grp ($cur;
          ($grp.hooks | map(select(.command as $c | ($have | index($c)) == null))) as $new
          | if ($new | length) == 0 then .
            else .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{matcher: $grp.matcher, hooks: $new}]) end)' "$settings")
    if [ "$(jq -S . "$settings")" = "$(printf '%s' "$merged" | jq -S .)" ]; then
      SKIPPED+=(".claude/settings.json (hooks already wired)")
    else
      if [ "$DRY" -eq 0 ]; then printf '%s\n' "$merged" > "$settings"; fi
      APPENDED+=(".claude/settings.json (hook entries added)")
    fi
  else
    FLAGGED+=(".claude/settings.json is not valid JSON; hooks not wired")
  fi
fi

# 3. CLAUDE.md ---------------------------------------------------------------
claude_md="$TARGET/CLAUDE.md"
detect_test_cmd() {
  local cmd=""
  if [ -f "$claude_md" ]; then
    cmd=$(grep -m1 -E '^[[:space:]]*-[[:space:]]*Test:' "$claude_md" | sed -E 's/^[[:space:]]*-[[:space:]]*Test:[[:space:]]*//; s/[[:space:]]*\(.*$//; s/[[:space:]]+$//')
  fi
  if [ -z "$cmd" ] && [ -f "$TARGET/Makefile" ] && grep -qE '^test:' "$TARGET/Makefile"; then cmd="make test"; fi
  if [ -z "$cmd" ] && [ -f "$TARGET/package.json" ] && jq -e '.scripts.test' "$TARGET/package.json" >/dev/null 2>&1; then cmd="npm test"; fi
  if [ -z "$cmd" ] && { [ -f "$TARGET/pyproject.toml" ] || [ -f "$TARGET/pytest.ini" ] || [ -f "$TARGET/setup.cfg" ]; }; then cmd="pytest"; fi
  if [ -z "$cmd" ] && [ -f "$TARGET/Cargo.toml" ]; then cmd="cargo test"; fi
  if [ -z "$cmd" ] && [ -f "$TARGET/go.mod" ]; then cmd="go test ./..."; fi
  echo "$cmd"
}
TEST_CMD=$(detect_test_cmd)
TEST_SRC="detected"
[ -n "$TEST_CMD" ] || { TEST_CMD="<your single test command>"; TEST_SRC="placeholder"; }
if [ -f "$claude_md" ] && grep -qE '^[[:space:]]*-[[:space:]]*Test:' "$claude_md"; then TEST_SRC="from CLAUDE.md"; fi

block_body() {
  printf '## Verifying your work\n\n- Test: %s (all pass; never skip or delete a failing test)\n\nRun it before reporting any task complete, and paste the output.\nIf a test fails, fix the code, not the test.\n' "$TEST_CMD"
}
BEGIN_RE='<!-- ai-native-sdlc:begin v[^ ]* -->'
END_RE='<!-- ai-native-sdlc:end sha256:[0-9a-f]* -->'
wrap() { # body -> marked block
  local body="$1" h
  h=$(printf '%s' "$body" | sha)
  printf '<!-- ai-native-sdlc:begin v%s -->\n%s\n<!-- ai-native-sdlc:end sha256:%s -->\n' "$VERSION" "$body" "$h"
}

if [ ! -f "$claude_md" ]; then
  name=$(basename "$TARGET")
  if [ "$DRY" -eq 0 ]; then
    { sed -n '1,/^## Verifying your work/p' "$SRC/templates/CLAUDE.md" | sed '$d' | sed "1s/.*/# $name/" | sed "s|<command> (all green)|$TEST_CMD (all green)|"
      wrap "$(block_body)"; } > "$claude_md"
  fi
  CREATED+=("CLAUDE.md (from templates/CLAUDE.md; run /init to fill the sections)")
elif grep -qE "$BEGIN_RE" "$claude_md"; then
  have_ver=$(grep -oE "$BEGIN_RE" "$claude_md" | head -1 | sed -E 's/.*begin v([^ ]*) .*/\1/')
  have_hash=$(grep -oE "$END_RE" "$claude_md" | head -1 | sed -E 's/.*sha256:([0-9a-f]*) .*/\1/')
  inner=$(awk -v b="$BEGIN_RE" -v e="$END_RE" '$0 ~ b {f=1; next} $0 ~ e {f=0} f' "$claude_md")
  inner_hash=$(printf '%s' "$inner" | sha)
  if [ "$inner_hash" != "$have_hash" ]; then
    FLAGGED+=("CLAUDE.md: the marked block was edited by hand (v$have_ver); left as is")
  elif [ "$have_ver" = "$VERSION" ] && [ "$inner" = "$(block_body)" ]; then
    SKIPPED+=("CLAUDE.md (block v$VERSION already present)")
  else
    if [ "$DRY" -eq 0 ]; then
      tmp=$(mktemp)
      bl=$(grep -nE "$BEGIN_RE" "$claude_md" | head -1 | cut -d: -f1)
      el=$(grep -nE "$END_RE" "$claude_md" | head -1 | cut -d: -f1)
      { head -n $((bl - 1)) "$claude_md"; wrap "$(block_body)"; tail -n +$((el + 1)) "$claude_md"; } > "$tmp"
      mv "$tmp" "$claude_md"
    fi
    APPENDED+=("CLAUDE.md (block updated v$have_ver -> v$VERSION)")
  fi
elif grep -qiE '^##+ *(verif|verification|before (you )?(finish|report)|definition of done)' "$claude_md"; then
  h=$(grep -niE '^##+ *(verif|verification|before (you )?(finish|report)|definition of done)' "$claude_md" | head -1)
  FLAGGED+=("CLAUDE.md already has a verification section at line ${h%%:*}; reconcile by hand. The playbook block is printed below.")
else
  if [ "$DRY" -eq 0 ]; then
    { [ -n "$(tail -c1 "$claude_md")" ] && echo; echo; wrap "$(block_body)"; } >> "$claude_md"
  fi
  APPENDED+=("CLAUDE.md (verification block, test command $TEST_SRC: $TEST_CMD)")
fi
if [ "$TEST_SRC" = placeholder ]; then
  FLAGGED+=("CLAUDE.md: no test command detected; replace '<your single test command>' before relying on the block")
fi
if [ -f "$claude_md" ] && [ "$(wc -l < "$claude_md")" -gt 60 ]; then
  FLAGGED+=("CLAUDE.md is $(wc -l < "$claude_md" | tr -d ' ') lines; the article asks for one page")
fi
if [ -e "$TARGET/AGENTS.md" ] && [ ! -L "$TARGET/AGENTS.md" ]; then
  FLAGGED+=("AGENTS.md exists as a file; if you want other agents to read CLAUDE.md, replace it with a symlink yourself")
fi

# 4. Summary -----------------------------------------------------------------
[ "$DRY" -eq 1 ] && say "dry run; nothing written"
say "mode $MODE, version $VERSION, target $TARGET"
for k in CREATED APPENDED SKIPPED FLAGGED; do
  eval "n=\${#$k[@]}"
  echo "$k ($n):"
  eval "for i in \"\${$k[@]}\"; do echo \"  \$i\"; done"
done
if printf '%s\n' "${FLAGGED[@]:-}" | grep -q 'reconcile by hand'; then
  echo; echo "Playbook verification block:"; block_body | sed 's/^/  /'
fi
echo "adopt: nothing was committed; review the diff, then commit."
exit 0
