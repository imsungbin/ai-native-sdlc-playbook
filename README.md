# ai-native-sdlc-playbook

Unofficial, faithful, runnable companion to
[The AI-Native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
by Louis Claxton (Anthropic), August 21, 2026. It contains the article's files
verbatim, templates for the artifacts the article names, one verification
command, and this repository's own record of running the loop. Nothing is added
on top of the article.

Not affiliated with or endorsed by Anthropic.

## The loop

The article makes each stage end by committing an artifact that the next stage
reads: an accepted `intent.md` triggers the requirements and design pass, an
approved `spec.md` triggers plan mode, `plan.md` is checked against the diff and
its tests, the PR carries the review findings, and a breached control band in
production writes the next `intent.md`. The chain of commits is the audit trail.

| Stage | Artifact | Where it lives here |
| --- | --- | --- |
| Plan | intent.md | intent/&lt;NNNN&gt;-&lt;slug&gt;/intent.md |
| Design | spec.md | intent/&lt;NNNN&gt;-&lt;slug&gt;/spec.md |
| Build | plan.md, CLAUDE.md, skills, hooks, agents | intent/.../plan.md, CLAUDE.md, .claude/ |
| Test | feedback loop, evals | Makefile to scripts/validate.sh, evals/, .github/workflows/agent-evals.yml |
| Deploy | REVIEW.md, approval-gate hook | REVIEW.md, .claude/settings.json, .claude/hooks/production-gate.sh |
| Maintain | bands.yaml, intent.md again | bands.yaml, .claude/skills/intent-template/ |

## Quickstart

1. Clone the repository, then run the verification command.

   ```
   make test
   ```

   Expected last line: `validate: all checks passed`.

2. Copy into your own project: `CLAUDE.md` (rewrite it for your codebase, keeping
   the article's structure), `REVIEW.md`, `bands.yaml`, `.claude/`, `templates/`,
   `evals/`, and the `Makefile` target or an equivalent single test command.

3. Run one change through the loop.

   - Stage 1: in Claude Code, ask for an intent. The `intent-template` skill
     triggers. Review what it wrote, then commit `intent.md` on its own.
   - Stage 2: run the slash command, review the result, then commit `spec.md`.

     ```
     /spec intent/0001-your-change/intent.md
     ```

   - Stage 3: start Claude Code in plan mode, give it `intent.md` and `spec.md`,
     iterate until the plan stands on its own, commit `plan.md`, then implement.
   - Stage 4: run `make test` before calling anything done. The verification
     block in `CLAUDE.md` enforces this by instruction.
   - Stage 5: `REVIEW.md` drives the review passes. `production-gate.sh` blocks
     any Bash command containing both "deploy" and "production" unless
     `RELEASE_APPROVAL` is set.
   - Stage 6: `bands.yaml` holds the response tiers. Your detection script (not
     shipped here, see below) writes the next `intent.md` through the
     `intent-template` skill.

4. Set the `ANTHROPIC_API_KEY` repository secret, or disable the "Agent evals"
   workflow. Its nightly schedule fails without the secret.
5. If you use a coding agent other than Claude Code, it finds the same
   instructions at `AGENTS.md` and the same skills under `.agents/skills/`; both
   are symbolic links. On Windows, set `git config core.symlinks true` before
   cloning, or they check out as text files.

## File map

| Path | Origin | What to change for your org |
| --- | --- | --- |
| README.md | Authored | Rewrite for your repository. |
| LICENSE | Authored | Your copyright holder, or your own license. |
| CLAUDE.md | Authored | Rewrite entirely for your codebase; keep the structure and the verification block. |
| AGENTS.md | Authored, symlink to CLAUDE.md | Keep if you run agents that read `AGENTS.md`; otherwise delete. |
| .agents/skills | Authored, symlink to .claude/skills | Keep if you run agents that scan `.agents/skills/`; otherwise delete. |
| REVIEW.md | Article, verbatim | Adjust the "Do not report" paths (`src/gen/` is the article's example) and the nit cap. |
| bands.yaml | Article, verbatim | Your metric, your baseline window, and the routes your agent may take. |
| Makefile | Authored | Point `test` at your real test command. |
| .gitignore | Authored | Add whatever your toolchain drops. |
| .claude/settings.json | Article, verbatim | Add your own gates; non-negotiable ones belong in managed settings instead. |
| .claude/hooks/production-gate.sh | Article, verbatim | Define what counts as approval in your change process. |
| .claude/skills/secure-api-review/SKILL.md | Article, verbatim | Replace with your own API security policy, and supply the `scripts/check-endpoints.sh` it calls. |
| .claude/skills/intent-template/SKILL.md | Authored | Keep if you keep `templates/intent.md`; otherwise point it at your template. |
| .claude/agents/verifier.md | Article, verbatim | Replace `make run` with the command that starts your app. |
| .claude/commands/spec.md | Article prompt, verbatim, plus one authored line | Name your own skills and standards in the prompt. |
| .github/workflows/agent-evals.yml | Article, verbatim | Needs an `ANTHROPIC_API_KEY` secret; adjust the schedule and the allowed tools. |
| evals/check.sh | Authored | Extend the checks your evals need. |
| evals/001-verification-command.json | Authored | Replace with 20 to 50 real tasks from your recent work. |
| scripts/validate.sh | Authored | Replace with your real test suite, or drop it once you have one. |
| templates/intent.md | Authored | Your organization's agreed intent fields. |
| templates/spec.md | Authored | Your organization's agreed spec fields. |
| templates/plan.md | Authored | Your organization's agreed plan fields. |
| intent/0001-bootstrap-playbook-repo/intent.md | Authored, this repo's own record | Delete; start your own `intent/0001-...`. |
| intent/0001-bootstrap-playbook-repo/spec.md | Authored, this repo's own record | Delete. |
| intent/0001-bootstrap-playbook-repo/plan.md | Authored, this repo's own record | Delete. |
| intent/0002-multi-agent-entry-points/intent.md | Authored, this repo's own record | Delete. |
| intent/0002-multi-agent-entry-points/spec.md | Authored, this repo's own record | Delete. |
| intent/0002-multi-agent-entry-points/plan.md | Authored, this repo's own record | Delete. |
| examples/article/README.md | Authored | Delete with the folder. |
| examples/article/intent.md | Article, verbatim | Reference only; the article's fictional example. |
| examples/article/plan.md | Article, verbatim | Reference only; the article's fictional example. |
| examples/article/CLAUDE.md | Article, verbatim | Reference only; the article's payments-service example plus its verification block. |
| examples/article/managed-settings.json | Article, verbatim | Reference only; managed settings are deployed by MDM or the admin console, not from a repository. |
| examples/article/triage-step.yml | Article, verbatim | Reference only; the article's pipeline triage step. |

## This repository's own loop record

`intent/0001-bootstrap-playbook-repo/` is the real record of building this
repository, not a worked fiction. The three files were committed in stage order,
one commit each, before the repository they describe was finished.

```
git log --reverse --format='%h %ad %s' --date=short
```

The first three commits are the intent, the spec, and the plan.
`intent/0002-multi-agent-entry-points/` is the second change run through the
same loop, again committed intent, spec, plan, then build.

## Author's calls (decisions the article does not make)

1. One directory per change, `intent/<NNNN>-<slug>/`, holding the triple. The
   article calls for "an intent/ folder in the product repo" and for committing
   `spec.md` alongside `intent.md`. Adding `plan.md` keeps the whole audit trail
   for one change in one place.
2. The `templates/spec.md` headings. The article ships no `spec.md`, only the
   prompt that produces one, so the headings come from what that prompt asks for
   and what its review step checks.
3. The Stage 2 prompt lives at `.claude/commands/spec.md` with one line prepended
   naming the file argument. The article says to "codify it as an
   organization-level slash command" but does not print the command file.
4. The intent template is a skill that references `templates/intent.md`. Article
   Stage 1 step 3 calls for "the organization's template, which can be encoded as
   a skill." The same skill covers Stage 6, where the agent writes its diagnosis
   as an `intent.md` in the Stage 1 format.
5. `make test`, running `scripts/validate.sh`, is this repository's single
   feedback-loop command. Article Stage 4 step 1 requires one command that exits
   non-zero on failure but does not say what it should check in a repository like
   this one.
6. A minimal `evals/`, one eval and one `check.sh`, so the article's
   `agent-evals.yml` runs unchanged over `evals/*.json`.
7. `examples/article/` holds the article's illustrations that are not live
   configuration here, and the article's two `CLAUDE.md` blocks are concatenated
   into one file because they are two sections of the same file.
8. `bands.yaml` sits at the repository root. The article prints the file but does
   not say where it lives, and the deterministic detection script it configures is
   not shipped here (see the next section).
9. This repository's own bootstrap is run through the loop for real, in stage
   order, as the worked example, instead of inventing a fictional project.
10. `AGENTS.md` and `.agents/skills` are symbolic links to `CLAUDE.md` and
    `.claude/skills`. The article is written for Claude Code and places
    institutional knowledge in those two locations; other coding agents read
    `AGENTS.md` and scan `.agents/skills/`. Links give them the same files with
    one source of truth and no copy to drift.

## What this repo does not contain, and why

Product features, not files. The article describes these, but they are configured
in Anthropic's products or in an organization's admin surface rather than in a
repository, so they are out of scope here and are not faked.

- MCP wiring for deployment tooling and legacy systems (Stage 5 CI/CD step 4;
  the Stage 3 sidebar on legacy systems and the source of truth).
- Sandboxing and managed settings (Stage 5, "Managed settings for a regulated
  enterprise"). The JSON is kept under `examples/article/` for reference only,
  since managed settings are deployed by MDM or the admin console and a file in a
  repository cannot enforce them.
- Claude Security recurring codebase scans (Stage 6).
- Claude Tag on call in Slack (Stage 6).

Described in prose, with no code in the article. Write your own; the article
states what each must do.

- The Stage 6 detection script: deterministic, rolling mean and standard
  deviation, Western Electric rules, unit tested, with no model involved.
- The Stage 4 hook that blocks edits to test files during a fix task.
- The Stage 3 hook that keeps `plan.md` in sync with the diff.
- The Stage 5 slash command that babysits a PR to green.
- The managed Code Review service or the `claude-code-action` wiring.
- Claude Design mocks (Stage 2).

## Verification

`make test` runs `scripts/validate.sh`, which checks that:

- every file this repository is meant to contain exists and is non-empty;
- `AGENTS.md` and `.agents/skills` are symbolic links pointing at `CLAUDE.md`
  and `../.claude/skills` and resolve;
- `production-gate.sh`, `evals/check.sh` and `scripts/validate.sh` pass
  `bash -n` and are executable;
- `.claude/settings.json`, `examples/article/managed-settings.json` and every
  `evals/*.json` parse as JSON, and every eval carries a string `prompt`;
- `bands.yaml`, `agent-evals.yml` and `triage-step.yml` parse as YAML (skipped
  with a warning if neither a Python `yaml` module nor ruby is available);
- the production gate exits 2 on a production deploy with no `RELEASE_APPROVAL`,
  exits 0 with it, and exits 0 on an unrelated command;
- both `SKILL.md` files and `agents/verifier.md` open with frontmatter carrying a
  `name:` line;
- `REVIEW.md`, `CLAUDE.md` and the templates start with a markdown heading.

It prints one line per check and ends with `validate: all checks passed`. Any
failure prints `FAIL:` and exits 1.

## Attribution and license

The article and the code blocks reproduced here are by Louis Claxton and are
copyright Anthropic. They are reproduced for reference, with attribution and
unmodified, in
[The AI-Native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook).
Everything authored in this repository is MIT licensed; see [LICENSE](LICENSE).
