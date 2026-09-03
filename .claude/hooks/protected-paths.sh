#!/bin/bash
# Completes article Play 3f: hooks that "block edits to protected paths
# (generated classes, frozen packages)". Wire on PreToolUse with matcher
# "Edit|Write|MultiEdit".
#
# Patterns come from .claude/protected-paths.txt in the project, one shell
# glob per line, matched against the path relative to the project root.
# Lines starting with # are comments. No file, no patterns: allow everything.
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
list="$root/.claude/protected-paths.txt"
[ -f "$list" ] || exit 0

path=$(jq -r '.tool_input.file_path // .tool_input.path // ""' < /dev/stdin)
[ -n "$path" ] || exit 0
rel="${path#"$root"/}"

while IFS= read -r pat; do
  pat="${pat%%#*}"; pat="${pat%"${pat##*[![:space:]]}"}"
  [ -n "$pat" ] || continue
  # shellcheck disable=SC2254
  case "$rel" in
    $pat)
      echo "Protected path: $rel matches '$pat' in .claude/protected-paths.txt." >&2
      echo "Edits here are not allowed from a session. Say what needs to change and why; the path owner changes it." >&2
      exit 2 ;;
  esac
done < "$list"
exit 0
