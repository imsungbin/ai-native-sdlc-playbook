# Intent: install the playbook as a plugin, never by piping a script
Author: imsungbin (repo owner). Status: accepted.

## Problem
Adopting the repository meant reading a file map and copying by hand. The
obvious shortcut, curl piped to sh, is denied by the article's own managed
settings and would install hooks that run on every tool call from an
unreviewed script.

## Proposed outcome
The repository is a Claude Code plugin marketplace. Two commands install
the skills, agent, commands and hooks. A third, /sdlc-init, places the
repo-root files into the current project without overwriting anything,
appends one marked block to CLAUDE.md, and stops before committing. A
standalone script does the same for people without the plugin system.

## Affected users and systems
Adopters; enterprise admins allowlisting marketplaces; this repository's
own CLAUDE.md, which stays this repository's.

## Constraints
A file that exists is never modified. CLAUDE.md gets exactly one block,
behind markers with a content hash, so upgrades and hand edits are told
apart. Nothing is committed by the installer.

## Open questions
Whether the plugin should also ship the workflows. It does not; they are
repository files and go through /sdlc-init.
