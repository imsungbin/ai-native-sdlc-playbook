# Spec: let other coding agents read the same instructions and skills (from intent.md 2026-09-03)
Status: accepted.

## Requirements
Two symbolic links, tracked in git:
- `AGENTS.md` -> `CLAUDE.md`. AGENTS.md is the file most non-Claude coding
  agents read at the repository root.
- `.agents/skills` -> `../.claude/skills`. `.agents/skills/` is the
  directory those agents scan for skills in the SKILL.md format the article
  uses.

The targets stay where the article places them. Nothing is copied.
`scripts/validate.sh` checks that both links exist, are links, and resolve.
The README file map and author's calls record the decision.

## Design
Relative links only, so a clone anywhere resolves. No content changes to
CLAUDE.md or any skill. No third link at the root (`skills/`); it is not a
path any agent scans by default.

## Open questions from intent.md
- Root-level `skills/` alias: carried forward; not added.

## Areas of concern
On Windows, git checks out symbolic links as plain text files containing the
link target unless `core.symlinks` is true. The README says so in one line.

## Skills applied
None; written by hand.
