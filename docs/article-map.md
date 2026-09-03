# Article map

One line per file that implements something the article says. V is verbatim
(hash-checked by `verbatim.lock`), C is completed from the article's prose,
I is the install layer, R is this repository's own record and tooling.

| File | Layer | Article | The sentence it implements |
| --- | --- | --- | --- |
| templates/intent.md | R | Stage 1, template example | "an agreed template" |
| .claude/skills/intent-template/SKILL.md | R | Stage 1, step 3 | "the organization's template, which can be encoded as a skill" |
| .claude/commands/spec.md | V+R | Stage 2, step 3 | "codify it as an organization-level slash command" |
| templates/spec.md | R | Stage 2, step 4 | what the prompt asks for and what the review step checks |
| templates/plan.md | R | Play 3a, example | the four headings of the example plan.md |
| .claude/hooks/plan-sync.sh | C | Play 3a, step 7 | "consider a hook that enforces the synchronization" |
| CLAUDE.md, templates/CLAUDE.md | R, I | Play 3d | "cut it down to day-one knowledge ... keep it under one page" |
| .claude/skills/secure-api-review/SKILL.md | V | Play 3e, example | the example skill |
| scripts/check-endpoints.sh | C | Play 3e, example, last line | "Run scripts/check-endpoints.sh and include its output" |
| .claude/hooks/protected-paths.sh | C | Play 3f | "block edits to protected paths (generated classes, frozen packages)" |
| .claude/agents/verifier.md | V | Play 3g, example | the example subagent |
| Makefile, scripts/validate.sh | R | Stage 4, step 1 | "wrap it in a single target ... exiting non-zero on failure" |
| CLAUDE.md, "Verifying your work" | R | Stage 4, example | the verification block |
| .claude/hooks/protect-tests.sh | C | Stage 4, step 7 | "a hook blocking test file edits during a fix task" |
| .github/workflows/test.yml | C | Stage 4, governance | "logged in ... the PR check run" |
| .github/workflows/agent-evals.yml | V | Play 4b, example | the CI config |
| evals/check.sh, evals/*.json | R, C | Play 4b, steps 1 and 2 | "prompt + checks defining acceptable" |
| REVIEW.md, templates/REVIEW.md | V, I | Play 5a, example | the review policy |
| .claude/commands/babysit-pr.md | C | Play 5a, step 4 | "a custom slash command sweeps unresolved comments and failing checks until the PR is green" |
| .claude/settings.json, .claude/hooks/production-gate.sh | V | Play 5b, example | the gate |
| .claude/hooks/hooks.json | I | Play 5b, step 3 | "team hooks in .claude/settings.json in git" (plugin form) |
| examples/article/managed-settings.json | V | Stage 5, sidebar | managed settings, reference only |
| examples/article/triage-step.yml | V | Play 5c, example | the triage step |
| bands.yaml | V | Play 6a, example | the tiers |
| scripts/detect-band.py, scripts/test_detect_band.py | C | Play 6a, step 2 | "mean and standard deviation on a rolling window, with rules like Western Electric; version controlled, unit tested; no model" |
| .github/workflows/bands.yml | C | Play 6a, step 4 | "a scheduled workflow in GitHub" |
| .claude-plugin/, install/ | I | Play 3e, step 3 | "distribute org-wide via plugin" |
| verbatim.lock, scripts/check-verbatim.sh | R | (this repo) | the faithfulness guarantee |
| docs/article-blocks.sha256, scripts/check-article.sh | R | (this repo) | detects revisions to the article's code blocks |

Not implemented, because they are products or admin surfaces rather than
files: MCP wiring for release tooling and legacy systems, sandboxing and
managed settings enforcement, Claude Security scans, Claude Tag on call, the
managed Code Review service, Claude Design mocks.
