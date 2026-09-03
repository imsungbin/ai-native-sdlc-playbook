# Plan: let other coding agents read the same instructions and skills (from intent.md 2026-09-03)

## Files that change
AGENTS.md (new symlink), .agents/skills (new symlink),
scripts/validate.sh, README.md, CLAUDE.md.

## Order of work
1. Create the two relative symlinks with `ln -s`.
2. Add a symlink check to scripts/validate.sh and list the two paths.
3. README: two rows in the file map, author's call 10, one Windows note
   in Quickstart, one bullet under Verification.
4. CLAUDE.md: one architecture line naming the links.
5. `make test`, then one build commit.

## Risks
A tool that follows the link and edits CLAUDE.md through AGENTS.md is fine;
a tool that replaces the link with a file would fork the content. The
validator catches that on the next run.

## Proof
`make test` ends with "validate: all checks passed" and prints
"ok: symlink AGENTS.md -> CLAUDE.md" and
"ok: symlink .agents/skills -> ../.claude/skills".
`readlink AGENTS.md` prints CLAUDE.md; `ls .agents/skills/` lists both skills.
