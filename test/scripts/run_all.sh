#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")"
pass=0
fail=0
failed=()

for t in *_test.sh *_test.py; do
  [ -f "$t" ] || continue
  echo "--- $t"
  if [[ "$t" == *.py ]]; then
    python3 "$t"
  else
    bash "$t"
  fi
  if [ $? -eq 0 ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failed+=("$t")
  fi
done

echo
echo "script tests: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
  printf 'failed: %s\n' "${failed[@]}"
  exit 1
fi
