#!/bin/bash
# Checks one eval result. Called by .github/workflows/agent-evals.yml as:
#   ./evals/check.sh "$eval" result.json
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: check.sh EVAL_JSON RESULT_JSON" >&2
  exit 1
fi

eval_json="$1"
result_json="$2"

for f in "$eval_json" "$result_json"; do
  if ! jq -e . "$f" >/dev/null 2>&1; then
    echo "check: $f is not valid JSON" >&2
    exit 1
  fi
done

name=$(jq -r '.name // "unnamed"' "$eval_json")

if [ "$(jq -r '.is_error // false' "$result_json")" = "true" ]; then
  echo "eval $name: the run reported an error" >&2
  exit 1
fi

result=$(jq -r '.result // ""' "$result_json")

while IFS= read -r expected; do
  [ -n "$expected" ] || continue
  case "$result" in
    *"$expected"*) ;;
    *) echo "eval $name: result does not contain \"$expected\"" >&2; exit 1 ;;
  esac
done < <(jq -r '.expect.result_contains[]? ' "$eval_json")

if ! make test; then
  echo "eval $name: make test failed" >&2
  exit 1
fi

echo "eval $name: pass"
