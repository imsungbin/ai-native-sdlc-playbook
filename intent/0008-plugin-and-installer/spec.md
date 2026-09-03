# Spec: plugin and installer (from intent.md 2026-09-03)
Status: accepted.

## Requirements
- `.claude-plugin/plugin.json` pointing commands, agents, skills and hooks
  at the existing `.claude/` paths; `.claude-plugin/marketplace.json` with
  the plugin at source "./".
- `.claude/hooks/hooks.json`: the four hooks with CLAUDE_PLUGIN_ROOT paths.
- `install/adopt.sh --into DIR [--plugin|--standalone] [--dry-run]`,
  driven by `install/MANIFEST`. Plugin mode places root files only;
  standalone also copies .claude components and merges hook entries into
  settings.json without duplicating any.
- CLAUDE.md: create from templates/CLAUDE.md if absent; else append the
  verification block behind `<!-- ai-native-sdlc:begin vX -->` and
  `<!-- ai-native-sdlc:end sha256:H -->`; existing verification heading
  means flag and print, not write; hand-edited block means flag, not
  replace; older version with intact hash means replace in place.
- Test command detected from an existing Test: line, then Makefile,
  package.json, pyproject, Cargo.toml, go.mod; else a placeholder that is
  flagged.
- `templates/CLAUDE.md`, `templates/REVIEW.md`, `.claude/commands/sdlc-init.md`.
- `scripts/test_adopt.sh` covers all of the above.

## Design
bash and jq. Summary in four lists: created, appended, skipped, flagged.

## Open questions from intent.md
- Workflows via plugin: answered, no.

## Areas of concern
Windows without symlink support is unaffected; the installer creates no
links.

## Skills applied
None.
