# ai-native-sdlc-playbook

Companion to Anthropic's "The AI-Native SDLC playbook" (Louis Claxton,
2026-08-21). Three layers: the article's files verbatim (hash-locked), the
pieces the article describes in prose implemented, and a plugin plus
installer that place them into another repo. Nothing the article does not
call for.

## Commands
- Test: make test (runs scripts/validate.sh; ends with
  "validate: all checks passed")
- Lock: make lock (rewrites verbatim.lock; only after re-checking the article)
- Article drift: scripts/check-article.sh (network; not part of make test)

## Conventions
- One change = one directory intent/<NNNN>-<slug>/ holding intent.md,
  spec.md, plan.md, committed in that order, one commit each. The
  pre-publication record is on the history branch and tag v0.1.0; 0003
  to 0008 landed together in the v0.2.0 commit.
- Every file has a layer: V verbatim, C completed, I install, R this repo.
  docs/article-map.md ties each C file to the article sentence it implements.
- Verbatim files are listed in verbatim.lock and .claude/protected-paths.txt.
  They are never edited; make test fails if one changes.
- Templates live in templates/. Skills and commands reference them.

## Architecture
- .claude/ is both this repo's live config and the plugin's component root;
  .claude-plugin/ holds the manifests. hooks.json wires all four hooks for
  the plugin; settings.json (verbatim) wires only the gate here.
- install/adopt.sh, driven by install/MANIFEST, is what /sdlc-init runs.
- scripts/ holds the validator, the hash check, the detector and the tests.
- AGENTS.md and .agents/skills are symlinks to CLAUDE.md and .claude/skills.
  Edit the targets, never the links.

## Things Claude gets wrong
- Do not add anything the article does not describe. If it is in the article
  as prose, it is layer C and needs an intent/ triple and an article-map row.
  If it is not in the article at all, it does not go in.
- Do not edit verbatim files to make them "work"; the file map says what an
  adopter replaces. The production gate blocks any Bash command that
  contains both "deploy" and "production", including heredocs; use Write.
- Do not invent example projects, authors, or incidents.
- BSD sed and awk: no \s, no newlines in awk -v. CI runs on Linux, dev on macOS.

## Verifying your work

- Test: make test (all checks pass; never skip or delete a failing check)

Run it before reporting any task complete, and paste the output.
If a check fails, fix the file, not the check.
