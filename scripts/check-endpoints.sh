#!/bin/bash
# Completes the last line of the article's secure-api-review skill, which
# runs scripts/check-endpoints.sh and includes its output in the summary.
# The article does not say what the script checks, so this is the smallest
# honest thing: an inventory of endpoint declarations the skill's four rules
# apply to, one per line as file:line: declaration. The policy judgement is
# the skill's job, not this script's. Exit 0 always; a missing inventory is
# a finding for the reviewer, not a build failure.
set -uo pipefail
root="${1:-.}"
pattern='@(app|router|api|bp|blueprint)\.(get|post|put|patch|delete|route)\(|\b(app|router|server)\.(get|post|put|patch|delete|all)\(|@(Get|Post|Put|Patch|Delete|Request)Mapping\b|@(Get|Post|Put|Patch|Delete)\(|\[Http(Get|Post|Put|Patch|Delete)\]|^\s{2}/[A-Za-z0-9_{}/.-]*:\s*$'
hits=$(grep -rnE --include='*.py' --include='*.js' --include='*.ts' --include='*.tsx' --include='*.java' --include='*.kt' --include='*.cs' --include='*.go' --include='*.rb' --include='*.yaml' --include='*.yml' \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=vendor \
  "$pattern" "$root" 2>/dev/null | sed 's/^\.\///')
if [ -z "$hits" ]; then
  echo "check-endpoints: no endpoint declarations found under $root"
  echo "Apply the four rules to any endpoint the change introduces by hand."
  exit 0
fi
count=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
echo "check-endpoints: $count endpoint declaration(s) to review against the four rules"
printf '%s\n' "$hits"
echo "For each: gateway JWT, schema validation with unknown fields rejected, audit event on state change, no pii fields in logs or errors."
exit 0
