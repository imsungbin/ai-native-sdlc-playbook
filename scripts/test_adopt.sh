#!/bin/bash
# Behavior tests for install/adopt.sh: never overwrite, one marked block in
# CLAUDE.md, idempotent, conflicts reported not resolved.
set -o pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd); ADOPT=$ROOT/install/adopt.sh
if command -v sha256sum >/dev/null 2>&1; then SHA="sha256sum"; else SHA="shasum -a 256"; fi
FAILED=0
ok()   { echo "ok: $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }
tree_hash() { (cd "$1" && find . -type f | sort | xargs $SHA | $SHA | cut -c1-16); }
fresh() { t=$(mktemp -d); git -C "$t" init -q; echo "$t"; }

# 1. empty target, standalone: creates everything, second run changes nothing
t=$(fresh)
out=$("$ADOPT" --into "$t" --standalone)
[ -f "$t/REVIEW.md" ] && [ -f "$t/.claude/skills/secure-api-review/SKILL.md" ] && [ -f "$t/.claude/settings.json" ] \
  && ok "standalone install creates root files, skills and settings" || fail "standalone install creates root files, skills and settings"
grep -q 'ai-native-sdlc:begin v' "$t/CLAUDE.md" && grep -q 'ai-native-sdlc:end sha256:' "$t/CLAUDE.md" \
  && ok "created CLAUDE.md carries begin and end markers" || fail "created CLAUDE.md carries begin and end markers"
echo "$out" | grep -q "no test command detected" && ok "placeholder test command is flagged" || fail "placeholder test command is flagged"
h1=$(tree_hash "$t"); out2=$("$ADOPT" --into "$t" --standalone); h2=$(tree_hash "$t")
[ "$h1" = "$h2" ] && ok "second run is a no-op (tree unchanged)" || fail "second run is a no-op (tree unchanged)"
echo "$out2" | grep -q "CREATED (0)" && ok "second run reports nothing created" || fail "second run reports nothing created"
echo "$out2" | grep -q "block v.* already present" && ok "second run reports the block as already present" || fail "second run reports the block as already present"
rm -rf "$t"

# 2. plugin mode places no .claude components and no settings.json
t=$(fresh)
"$ADOPT" --into "$t" --plugin >/dev/null
[ ! -e "$t/.claude/skills" ] && [ ! -e "$t/.claude/settings.json" ] && [ -f "$t/bands.yaml" ] \
  && ok "plugin mode places root files only" || fail "plugin mode places root files only"
rm -rf "$t"

# 3. existing CLAUDE.md with a Test: line and no verification section: append, read the command
t=$(fresh)
printf '# Ledger service\n\n## Commands\n- Test: pytest -q\n\n## Conventions\n- Amounts are Decimal, never float.\n' > "$t/CLAUDE.md"
before=$(head -7 "$t/CLAUDE.md")
out=$("$ADOPT" --into "$t" --plugin)
[ "$(head -7 "$t/CLAUDE.md")" = "$before" ] && ok "existing lines above the block are untouched" || fail "existing lines above the block are untouched"
grep -q -- '- Test: pytest -q (all pass' "$t/CLAUDE.md" && ok "test command read from the existing Test: line" || fail "test command read from the existing Test: line"
[ "$(grep -c 'ai-native-sdlc:begin' "$t/CLAUDE.md")" -eq 1 ] && ok "exactly one block appended" || fail "exactly one block appended"
"$ADOPT" --into "$t" --plugin >/dev/null
[ "$(grep -c 'ai-native-sdlc:begin' "$t/CLAUDE.md")" -eq 1 ] && ok "rerun does not append a second block" || fail "rerun does not append a second block"

# 4. edited inside the markers: conflict reported, file untouched
sed -i.bak 's/never skip or delete a failing test/skip flaky ones/' "$t/CLAUDE.md" && rm -f "$t/CLAUDE.md.bak"
h1=$($SHA < "$t/CLAUDE.md"); out=$("$ADOPT" --into "$t" --plugin); h2=$($SHA < "$t/CLAUDE.md")
[ "$h1" = "$h2" ] && echo "$out" | grep -q "edited by hand" && ok "hand-edited block is left alone and flagged" || fail "hand-edited block is left alone and flagged"
rm -rf "$t"

# 5. older version with intact hash: block replaced, version bumped, rest untouched
t=$(fresh)
printf '# Svc\n\n## Commands\n- Test: make check\n' > "$t/CLAUDE.md"
"$ADOPT" --into "$t" --plugin >/dev/null
cur=$(jq -r .version "$ROOT/.claude-plugin/plugin.json")
sed -i.bak "s/begin v$cur/begin v0.0.1/" "$t/CLAUDE.md" && rm -f "$t/CLAUDE.md.bak"
out=$("$ADOPT" --into "$t" --plugin)
grep -q "begin v$cur" "$t/CLAUDE.md" && ! grep -q "begin v0.0.1" "$t/CLAUDE.md" && echo "$out" | grep -q "v0.0.1 -> v$cur" \
  && ok "older block is upgraded in place" || fail "older block is upgraded in place"
[ "$(head -4 "$t/CLAUDE.md")" = "$(printf '# Svc\n\n## Commands\n- Test: make check')" ] && ok "upgrade leaves the rest of the file alone" || fail "upgrade leaves the rest of the file alone"
rm -rf "$t"

# 6. existing verification section: nothing written, flagged, block printed
t=$(fresh)
printf '# Svc\n\n## Verifying your work\n- run pytest before finishing\n' > "$t/CLAUDE.md"
h1=$($SHA < "$t/CLAUDE.md"); out=$("$ADOPT" --into "$t" --plugin); h2=$($SHA < "$t/CLAUDE.md")
[ "$h1" = "$h2" ] && echo "$out" | grep -q "reconcile by hand" && echo "$out" | grep -q "Playbook verification block:" \
  && ok "existing verification section is flagged and left alone" || fail "existing verification section is flagged and left alone"
rm -rf "$t"

# 7. detection from Makefile and package.json
t=$(fresh); printf 'test:\n\ttrue\n' > "$t/Makefile"; "$ADOPT" --into "$t" --plugin >/dev/null
grep -q -- '- Test: make test (all pass' "$t/CLAUDE.md" && ok "detects make test from a Makefile" || fail "detects make test from a Makefile"; rm -rf "$t"
t=$(fresh); echo '{"scripts":{"test":"jest"}}' > "$t/package.json"; "$ADOPT" --into "$t" --plugin >/dev/null
grep -q -- '- Test: npm test (all pass' "$t/CLAUDE.md" && ok "detects npm test from package.json" || fail "detects npm test from package.json"; rm -rf "$t"

# 8. existing files are never overwritten
t=$(fresh); echo "mine" > "$t/REVIEW.md"; "$ADOPT" --into "$t" --plugin >/dev/null
[ "$(cat "$t/REVIEW.md")" = "mine" ] && ok "existing REVIEW.md is not overwritten" || fail "existing REVIEW.md is not overwritten"; rm -rf "$t"

# 9. settings.json merge: keeps the adopter's hooks, adds ours once
t=$(fresh); mkdir -p "$t/.claude"
echo '{"permissions":{"allow":["Bash(make test)"]},"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"./mine.sh"}]}]}}' > "$t/.claude/settings.json"
"$ADOPT" --into "$t" --standalone >/dev/null
jq -e '.permissions.allow[0] == "Bash(make test)"' "$t/.claude/settings.json" >/dev/null && ok "merge keeps existing settings" || fail "merge keeps existing settings"
jq -e '[.. | objects | select(has("command")) | .command] | (index("./mine.sh") != null) and (map(select(test("production-gate"))) | length == 1)' "$t/.claude/settings.json" >/dev/null \
  && ok "merge keeps the adopter's hook and adds ours" || fail "merge keeps the adopter's hook and adds ours"
h1=$($SHA < "$t/.claude/settings.json"); "$ADOPT" --into "$t" --standalone >/dev/null; h2=$($SHA < "$t/.claude/settings.json")
[ "$h1" = "$h2" ] && ok "settings merge is idempotent" || fail "settings merge is idempotent"
rm -rf "$t"

# 10. dry run writes nothing
t=$(fresh); "$ADOPT" --into "$t" --standalone --dry-run >/dev/null
[ ! -e "$t/CLAUDE.md" ] && [ ! -e "$t/REVIEW.md" ] && ok "dry run writes nothing" || fail "dry run writes nothing"; rm -rf "$t"

if [ "$FAILED" -ne 0 ]; then echo "test_adopt: failures above"; exit 1; fi
echo "test_adopt: all installer checks passed"
