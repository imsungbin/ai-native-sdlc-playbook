# ai-native-sdlc-playbook

Unofficial companion to Anthropic's "The AI-Native SDLC playbook"
(Louis Claxton, 2026-08-21). Contains the article's files and this repo's
own intent to spec to plan record. Nothing is added on top of the article.

## Commands
- Test: make test (runs scripts/validate.sh; healthy output ends with
  "validate: all checks passed")

## Conventions
- One change = one directory intent/<NNNN>-<slug>/ holding intent.md,
  spec.md, plan.md, committed in that order, one commit each.
- Files copied from the article are listed in README.md under
  "File map". They are copied verbatim and are not edited here.
- Templates live in templates/. Skills and commands reference them;
  they do not duplicate them.

## Architecture
- .claude/ holds the article's settings, hook, skills, agent, and the
  spec slash command. REVIEW.md and bands.yaml sit at the root as the
  article places them.
- examples/article/ holds the article's illustrations that are not live
  config here.
- evals/ and scripts/ exist only so the article's files run unmodified.
- AGENTS.md and .agents/skills are symlinks to CLAUDE.md and .claude/skills
  for other coding agents. Edit the targets, never the links.

## Things Claude gets wrong
- Do not add plays, hooks, scripts, or frameworks the article does not
  describe. If it is not in the article, it goes in README "Author's calls"
  or it does not go in.
- Do not edit verbatim files to make them "work" here; the README explains
  what an adopter replaces.
- Do not invent example projects, authors, or incidents.

## Verifying your work

- Test: make test (all checks pass; never skip or delete a failing check)

Run it before reporting any task complete, and paste the output.
If a check fails, fix the file, not the check.
