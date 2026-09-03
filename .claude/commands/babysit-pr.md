---
description: Sweep a PR's unresolved review comments and failing checks until it is green. Never merges.
allowed-tools: Bash(gh pr *), Bash(gh api *), Bash(gh run *), Bash(git *), Read, Edit, Write
---
Completes article Play 5a, step 4: for PRs Claude opened, "a custom slash
command sweeps unresolved comments and failing checks until the PR is green."

PR: $ARGUMENTS (a number, a URL, or blank for the PR of the current branch).

Loop until there is nothing left to do, at most six rounds:

1. `gh pr view` for state and branch. Stop if the PR is merged, closed, or a
   draft someone else owns.
2. `gh pr checks`. For each failing check, read the log with `gh run view --log-failed`,
   fix the cause in code, and note what changed. Never edit a test to make it
   pass; if a test is wrong, say so in the PR and leave it.
3. Unresolved review threads: `gh api graphql` on `reviewThreads(first: 50)`
   with `isResolved: false`. For each, make the change the reviewer asked for or
   reply with a one-line reason why not. Do not resolve threads yourself; the
   reviewer does.
4. Run the project's test command from CLAUDE.md before every push.
5. Commit with a message that names the thread or check it addresses, and push
   to the PR branch. Never force-push, never rebase, never touch main.
6. Re-run steps 2 and 3. Stop when checks are green and every thread has a
   fix or a reply.

End with a short summary: rounds run, checks fixed, threads addressed, threads
left for a person, and whether the PR is green. Do not merge; a person does.
