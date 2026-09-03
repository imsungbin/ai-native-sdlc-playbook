#!/bin/bash
# Completes article Stage 4, step 7: "a hook that blocks edits to test files
# during a fix task". Wire on PreToolUse with matcher "Edit|Write|MultiEdit".
#
# A fix task is declared by the engineer, not inferred:
#   SDLC_FIX_TASK=1 claude
# Outside a fix task the hook allows everything. Exit 2 blocks the edit and
# the message goes to Claude.
[ -n "${SDLC_FIX_TASK:-}" ] || exit 0

path=$(jq -r '.tool_input.file_path // .tool_input.path // ""' < /dev/stdin)
[ -n "$path" ] || exit 0

base=$(basename "$path")
is_test=0
case "$path" in
  */tests/*|*/test/*|*/__tests__/*|*/spec/*|tests/*|test/*|__tests__/*|spec/*) is_test=1 ;;
esac
case "$base" in
  test_*|*_test.*|*.test.*|*.spec.*|*Test.java|*Tests.java|*Spec.scala) is_test=1 ;;
esac

if [ "$is_test" -eq 1 ]; then
  echo "Fix task in progress (SDLC_FIX_TASK is set): test files are read-only." >&2
  echo "Blocked edit: $path" >&2
  echo "Make the code pass the existing test. If the test itself is wrong, say so and stop; a person changes the test." >&2
  exit 2
fi
exit 0
