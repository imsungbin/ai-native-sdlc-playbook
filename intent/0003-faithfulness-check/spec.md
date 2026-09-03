# Spec: prove the verbatim layer is verbatim (from intent.md 2026-09-03)
Status: accepted.

## Requirements
- `verbatim.lock`: one line per verbatim file, sha256 and path.
- `scripts/check-verbatim.sh`: verifies the lock; `--update` rewrites it.
  Fails on a changed file, a missing file, or a wrong entry count.
- `make test` runs it.
- `.github/workflows/test.yml` runs `make test` on pull requests and pushes
  to main; the ruleset requires it.
- `examples/article/managed-settings.json` restored to the article's exact
  bytes before locking.
- `docs/article-blocks.sha256` and `scripts/check-article.sh`: fingerprint of
  the article's code blocks; the script fetches and compares. Not part of
  `make test`.

## Design
Plain bash, sha256sum or shasum. The lock lists twelve files. The
protected-paths hook (0004) lists the same files so a session cannot edit
them either.

## Open questions from intent.md
- Article revisions: carried forward, now detectable.

## Areas of concern
None. Policy owner for the verbatim layer is the repo owner.

## Skills applied
None.
