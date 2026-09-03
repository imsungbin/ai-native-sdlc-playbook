# Plan: prove the verbatim layer is verbatim (from intent.md 2026-09-03)

## Files that change
verbatim.lock (new), scripts/check-verbatim.sh (new),
scripts/check-article.sh (new), docs/article-blocks.sha256 (new),
.github/workflows/test.yml (new), examples/article/managed-settings.json,
scripts/validate.sh, Makefile

## Order of work
1. Restore managed-settings.json to the article's bytes; byte-compare all twelve.
2. check-verbatim.sh, generate the lock.
3. Fingerprint the article's code blocks; check-article.sh.
4. test.yml; validate.sh calls check-verbatim.sh.

## Risks
The article page is rendered HTML; the fingerprint normalizes whitespace so
markup changes do not count as content changes.

## Proof
`make test` prints "ok: verbatim <path>" twelve times. Changing one byte of
REVIEW.md makes it fail. `scripts/check-article.sh` reports unchanged.
