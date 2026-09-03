# Spec: a runnable companion repo for the AI-Native SDLC playbook (from intent.md 2026-09-03)
Status: accepted.

## Requirements
The repository holds exactly 27 tracked files.

Copied from the article, verbatim:
- `REVIEW.md`
- `bands.yaml`
- `.claude/settings.json`
- `.claude/hooks/production-gate.sh`
- `.claude/skills/secure-api-review/SKILL.md`
- `.claude/agents/verifier.md`
- `.github/workflows/agent-evals.yml`
- `examples/article/intent.md`
- `examples/article/plan.md`
- `examples/article/CLAUDE.md`
- `examples/article/managed-settings.json`
- `examples/article/triage-step.yml`
- `.claude/commands/spec.md`, which is the article's Stage 2 prompt verbatim
  with one authored line prepended that names the file argument.

Authored for this repository:
- `README.md`, `LICENSE`, `CLAUDE.md`, `Makefile`, `.gitignore`
- `.claude/skills/intent-template/SKILL.md`
- `scripts/validate.sh`
- `evals/check.sh`, `evals/001-verification-command.json`
- `templates/intent.md`, `templates/spec.md`, `templates/plan.md`
- `examples/article/README.md`
- `intent/0001-bootstrap-playbook-repo/intent.md`, `spec.md`, `plan.md`

No file outside that list. No detection script, no test-file hook, no
plan-sync hook, no PR-babysit command, no badges, no CHANGELOG.

## Design
The files split three ways.

1. Live configuration, at the paths the article gives them: `REVIEW.md` and
   `bands.yaml` at the root, and `.claude/` holding the settings, the hook,
   the two skills, the agent, and the spec slash command. These are the
   article's files unedited, so an adopter can read the article and the repo
   side by side.
2. Article illustrations under `examples/article/`. These describe the
   article's fictional claims-status and payments-service examples, or
   configuration that a repository file cannot enforce (managed settings are
   deployed by MDM or the admin console). Keeping them out of `.claude/`
   stops them being mistaken for this repo's live configuration.
3. This repository's own record. `CLAUDE.md` at the root is real and written
   for this repo, following the article's structure plus its verification
   block. Each change is one directory, `intent/<NNNN>-<slug>/`, holding
   `intent.md`, `spec.md` and `plan.md`, committed in that order, one commit
   each, so the git history is itself the stage-ordered audit trail.

The feedback loop is a single command: `make test` runs `scripts/validate.sh`,
which asserts the file tree, syntax-checks the three shell scripts, parses the
JSON and YAML, functionally tests the production gate at its three documented
outcomes, and checks the markdown frontmatter and headings. It exits non-zero
on any failure, as Stage 4 requires.

`evals/` holds one eval and one `check.sh`, the minimum that lets the
article's `agent-evals.yml` run unchanged over `evals/*.json`.

Templates live in `templates/`. The `intent-template` skill references
`templates/intent.md` rather than restating it, so the format has one home.

## Open questions from intent.md
Whether to publish the repository: carried forward. The repository is created
private; the decision to make it public is not taken here.

## Areas of concern
- `.github/workflows/agent-evals.yml` requires an `ANTHROPIC_API_KEY`
  repository secret and carries a nightly `cron` schedule. Without the secret
  the scheduled run fails. The file is the article's and is not edited here;
  the README tells the adopter to set the secret or disable the workflow.
  Policy owner: whoever administers the repository.
- `.claude/agents/verifier.md` says to start the app with `make run`, and
  `.claude/skills/secure-api-review/SKILL.md` says to run
  `scripts/check-endpoints.sh`. Both are the article's placeholders for a
  real service and do not resolve in this repository. They are left as
  printed and the README's file map says what an adopter replaces.
- `examples/article/managed-settings.json` is a control that a repository
  cannot enforce. It is kept for reference only, under `examples/article/`,
  and the README says so.

## Skills applied
None available at the time of writing; this spec was written by hand.
