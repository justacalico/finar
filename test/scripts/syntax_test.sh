#!/usr/bin/env bash
set -uo pipefail

fail=0
for script in ../../scripts/*.sh; do
  if bash -n "$script" 2>/dev/null; then
    echo "ok syntax $script"
  else
    echo "FAIL syntax $script"
    fail=1
  fi
done
exit $fail
