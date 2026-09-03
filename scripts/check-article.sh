#!/bin/bash
# Fetches the article and compares the fingerprint of its code blocks with
# docs/article-blocks.sha256. Run by hand or on a schedule, not by make test;
# it needs the network. A mismatch means the article was revised and the
# verbatim layer needs re-checking, not that this repository is broken.
set -euo pipefail
cd "$(dirname "$0")/.."
URL="https://claude.com/blog/the-ai-native-sdlc-playbook"
want=$(cut -d' ' -f1 docs/article-blocks.sha256)
have=$(curl -fsSL -A "Mozilla/5.0" "$URL" | python3 -c '
import sys,re,html,hashlib
s=sys.stdin.read()
blocks=[html.unescape(re.sub(r"<[^>]+>","",b)) for b in re.findall(r"<pre[^>]*>(.*?)</pre>",s,re.S)]
t=html.unescape(re.sub(r"<[^>]+>","",s))
a=t.find("{\n  \"permissions\""); b=t.find("\"requiredMinimumVersion\": \"2.1.193\"\n}")
ms=t[a:b+len("\"requiredMinimumVersion\": \"2.1.193\"\n}")] if a>0 and b>0 else ""
norm=lambda x:re.sub(r"\s+"," ",x).strip()
print(hashlib.sha256("\n".join(norm(x) for x in blocks+[ms]).encode()).hexdigest())')
if [ "$have" = "$want" ]; then echo "check-article: code blocks unchanged since $(grep -o 'fetched [0-9-]*' docs/article-blocks.sha256)"
else echo "check-article: the article's code blocks changed (have $have, lock $want). Re-check the verbatim layer."; exit 1; fi
