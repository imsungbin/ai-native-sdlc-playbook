#!/bin/bash
# Behavior tests for the completed hooks (article Play 3a step 7, Play 3f,
# Stage 4 step 7). Each hook is fed the JSON a PreToolUse hook receives.
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
FAILED=0
ok()   { echo "ok: $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }
expect_rc() { # want name payload env... -- cmd
  local want="$1" name="$2" payload="$3"; shift 3
  local rc=0
  echo "$payload" | env "$@" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq "$want" ]; then ok "$name (exit $rc)"; else fail "$name (got exit $rc, want $want)"; fi
}

PT=$ROOT/.claude/hooks/protect-tests.sh
edit() { printf '{"tool_input":{"file_path":"%s"}}' "$1"; }
expect_rc 2 "protect-tests blocks tests/test_x.py during a fix task"   "$(edit tests/test_x.py)"      SDLC_FIX_TASK=1 "$PT"
expect_rc 2 "protect-tests blocks src/foo.spec.ts during a fix task"   "$(edit src/foo.spec.ts)"      SDLC_FIX_TASK=1 "$PT"
expect_rc 2 "protect-tests blocks FooTest.java during a fix task"      "$(edit src/FooTest.java)"     SDLC_FIX_TASK=1 "$PT"
expect_rc 0 "protect-tests allows src/foo.py during a fix task"        "$(edit src/foo.py)"           SDLC_FIX_TASK=1 "$PT"
expect_rc 0 "protect-tests allows tests outside a fix task"            "$(edit tests/test_x.py)"      -u SDLC_FIX_TASK "$PT"

PP=$ROOT/.claude/hooks/protected-paths.sh
expect_rc 2 "protected-paths blocks REVIEW.md in this repo"            "$(edit "$ROOT/REVIEW.md")"                 CLAUDE_PROJECT_DIR="$ROOT" "$PP"
expect_rc 2 "protected-paths blocks examples/article/* glob"           "$(edit "$ROOT/examples/article/plan.md")"  CLAUDE_PROJECT_DIR="$ROOT" "$PP"
expect_rc 0 "protected-paths allows README.md"                         "$(edit "$ROOT/README.md")"                 CLAUDE_PROJECT_DIR="$ROOT" "$PP"
tmp=$(mktemp -d); mkdir -p "$tmp/.claude"
expect_rc 0 "protected-paths allows everything with no list file"      "$(edit "$tmp/anything")"                   CLAUDE_PROJECT_DIR="$tmp" "$PP"
rm -rf "$tmp"

PS=$ROOT/.claude/hooks/plan-sync.sh
bashcmd() { printf '{"tool_input":{"command":"%s"}}' "$1"; }
repo=$(mktemp -d)
( cd "$repo" && git init -q && git config user.email t@t && git config user.name t
  mkdir -p intent/0001-x src && printf '# Plan: x\n\n## Files that change\nsrc/a.py (new), src/b.py\n\n## Order of work\n1.\n' > intent/0001-x/plan.md
  echo a > src/a.py; echo c > src/c.py; git add intent src/a.py && git commit -qm init )
expect_rc 0 "plan-sync ignores commands that are not git commit"      "$(bashcmd 'make test')"       CLAUDE_PROJECT_DIR="$repo" "$PS"
( cd "$repo" && git add src/c.py )
expect_rc 2 "plan-sync blocks a commit with a file outside the plan"  "$(bashcmd 'git commit -m x')" CLAUDE_PROJECT_DIR="$repo" "$PS"
( cd "$repo" && echo "src/c.py" >> intent/0001-x/plan.md && git add intent/0001-x/plan.md )
expect_rc 0 "plan-sync allows it when plan.md is staged in the same commit" "$(bashcmd 'git commit -m x')" CLAUDE_PROJECT_DIR="$repo" "$PS"
( cd "$repo" && git commit -qm c && echo b > src/b.py && git add src/b.py )
expect_rc 0 "plan-sync allows a planned file"                         "$(bashcmd 'git commit -m x')" CLAUDE_PROJECT_DIR="$repo" "$PS"
( cd "$repo" && git reset -q && rm -rf intent && git add -A )
expect_rc 0 "plan-sync allows everything when no plan.md exists"      "$(bashcmd 'git commit -m x')" CLAUDE_PROJECT_DIR="$repo" "$PS"
rm -rf "$repo"

if [ "$FAILED" -ne 0 ]; then echo "test_hooks: failures above"; exit 1; fi
echo "test_hooks: all hook checks passed"
