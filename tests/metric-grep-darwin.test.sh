#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
report="$work/report.md"
printf 'Demographic parity difference | -0.42 | 0.10\n' > "$report"

set +e
got_p=$(grep -iE 'demographic.parity.difference' "$report" | grep -oP '[-+]?[0-9]*\.?[0-9]+' | head -1)
p=$?
set -e
if [ "$p" -eq 0 ]; then
  echo "grep -oP unexpectedly succeeded" >&2
  exit 1
fi

got=$(grep -iE 'demographic.parity.difference' "$report" \
  | grep -oE '[-+]?[0-9]*\.?[0-9]+' | head -1 || true)
[ "$got" = "-0.42" ]
if grep -q 'grep -oP' "$root/action.yml"; then
  echo "action.yml still uses grep -oP" >&2
  exit 1
fi
echo "fairpipe grep darwin ok (grep -P exit $p, value $got)"
rm -rf "$work"
