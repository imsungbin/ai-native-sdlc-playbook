# Plan: plugin and installer (from intent.md 2026-09-03)

## Files that change
.claude-plugin/plugin.json (new), .claude-plugin/marketplace.json (new),
.claude/hooks/hooks.json (new), install/adopt.sh (new), install/MANIFEST (new),
install/protected-paths.template.txt (new), templates/CLAUDE.md (new),
templates/REVIEW.md (new), .claude/commands/sdlc-init.md (new),
scripts/test_adopt.sh (new), scripts/validate.sh, README.md, CLAUDE.md,
docs/article-map.md (new)

## Order of work
1. Manifests and hooks.json.
2. Templates and the command.
3. adopt.sh, then test_adopt.sh with ten cases.
4. Article map, README, CLAUDE.md rule change.

## Risks
BSD versus GNU sed and awk; the script uses POSIX classes and line-number
splicing so it runs on macOS and Linux runners alike.

## Proof
`scripts/test_adopt.sh` ends with "all installer checks passed". A second
run into the same directory changes no file.
