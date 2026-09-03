# Plan: a runnable companion repo for the AI-Native SDLC playbook (from intent.md 2026-09-03)

## Files that change
All 27 files are new.

Authored: README.md, LICENSE, CLAUDE.md, Makefile, .gitignore,
scripts/validate.sh, evals/check.sh, evals/001-verification-command.json,
templates/intent.md, templates/spec.md, templates/plan.md,
.claude/skills/intent-template/SKILL.md, examples/article/README.md,
intent/0001-bootstrap-playbook-repo/intent.md, spec.md, plan.md.

Verbatim from the article: REVIEW.md, bands.yaml, .claude/settings.json,
.claude/hooks/production-gate.sh,
.claude/skills/secure-api-review/SKILL.md, .claude/agents/verifier.md,
.github/workflows/agent-evals.yml, examples/article/intent.md,
examples/article/plan.md, examples/article/CLAUDE.md,
examples/article/managed-settings.json, examples/article/triage-step.yml.

Verbatim prompt with one authored line prepended:
.claude/commands/spec.md.

## Order of work
Eight commits, in stage order, so the history is the audit trail.

1. intent.md alone.
2. spec.md.
3. plan.md.
4. CLAUDE.md, Makefile, scripts/validate.sh, .gitignore: the repo's
   feedback loop, before the files it validates exist.
5. REVIEW.md, bands.yaml, all six .claude files, agent-evals.yml: the
   article's configuration, verbatim.
6. evals/check.sh and the one eval, so the article's workflow runs unchanged.
7. templates/ and examples/article/.
8. README.md and LICENSE.

Run `make test` before commit 4 and again before commit 8. It reports
missing files until commit 7; that is expected, and it must be all green
at commit 8. Then create the private repository and push.

## Risks
- The mirror escapes `*` as `\*` and `_` as `\_` inside the unfenced managed
  settings block. Copying it unchanged produces invalid JSON, so the escapes
  are stripped and the result is checked with `jq`.
- The Makefile recipe must be indented with a tab. A heredoc that expands
  tabs, or an editor that converts them, breaks `make test` with
  "missing separator".
- The executable bit on production-gate.sh and the two other scripts is easy
  to lose. validate.sh asserts `test -x` on all three so the loss is caught.
- Copying by hand risks silent drift from the article. Every verbatim file is
  extracted from the mirror by line range and diffed back against it.

## Proof
`make test` ends with "validate: all checks passed", including the three
production-gate cases: exit 2 for a production deploy with no
RELEASE_APPROVAL, exit 0 with it, and exit 0 for `make test`.
`git log --reverse --format='%h %ad %s' --date=short` shows the eight
commits in stage order, the first three being intent, spec and plan.
