#!/usr/bin/env python3
"""Filter coverage/lcov.info to remove untestable files from the report.

Untestable in unit tests:
- lib/l10n/* (ARB-generated localizations)
- lib/main.dart (entry point)
- lib/app.dart (top-level app widget)
- lib/pages/* (page widgets)
- lib/widgets/* (shared widgets)
- lib/**/widgets/* (sub-page widgets)
- Generated files: .g.dart
"""

import re
import sys
from pathlib import Path

LCOV_PATH = Path('coverage/lcov.info')

EXCLUDE_PREFIXES = (
    'lib/l10n/',
    'lib/main.dart',
    'lib/app.dart',
    'lib/pages/',
    'lib/widgets/',
)

EXCLUDE_SUBSTRINGS = (
    '/widgets/',
)

EXCLUDE_SUFFIXES = (
    '.g.dart',
)


def should_include(sf: str) -> bool:
    if sf.startswith(EXCLUDE_PREFIXES):
        return False
    if sf.endswith(EXCLUDE_SUFFIXES):
        return False
    if any(sub in sf for sub in EXCLUDE_SUBSTRINGS):
        return False
    return True


def main() -> int:
    if not LCOV_PATH.exists():
        print(f'{LCOV_PATH} not found', file=sys.stderr)
        return 1

    content = LCOV_PATH.read_text()
    records = content.split('end_of_record')
    kept = []
    total = covered = 0

    for rec in records:
        if not rec.strip():
            continue
        sf_match = re.search(r'^SF:(.+)$', rec, re.MULTILINE)
        if not sf_match:
            continue
        sf = sf_match.group(1)
        if not should_include(sf):
            continue
        kept.append(rec.strip() + '\nend_of_record\n')
        for line in rec.splitlines():
            if line.startswith('DA:'):
                total += 1
                hits = int(line.split(',')[1])
                if hits > 0:
                    covered += 1

    LCOV_PATH.write_text(''.join(kept))

    pct = (covered * 100 // total) if total else 0
    print(f'Filtered coverage: {covered}/{total} = {pct}%')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
