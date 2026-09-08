#!/usr/bin/env python3
"""Tests for scripts/filter_coverage.py."""

import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / 'scripts' / 'filter_coverage.py'


def make_lcov(tmp: Path) -> Path:
    cov_dir = tmp / 'coverage'
    cov_dir.mkdir()
    lcov = cov_dir / 'lcov.info'
    lcov.write_text(
        'SF:lib/main.dart\n'
        'DA:1,1\n'
        'DA:2,0\n'
        'end_of_record\n'
        'SF:lib/pages/home.dart\n'
        'DA:1,1\n'
        'DA:2,1\n'
        'end_of_record\n'
        'SF:lib/widgets/glass.dart\n'
        'DA:1,1\n'
        'DA:2,0\n'
        'end_of_record\n'
        'SF:lib/pages/detail/widgets/detail_card.dart\n'
        'DA:1,1\n'
        'DA:2,0\n'
        'end_of_record\n'
        'SF:lib/core/utils/platform.dart\n'
        'DA:1,1\n'
        'DA:2,1\n'
        'end_of_record\n'
        'SF:lib/core/services/download_service.g.dart\n'
        'DA:1,1\n'
        'DA:2,0\n'
        'end_of_record\n'
    )
    return lcov


def run_filter(lcov: Path) -> tuple[str, str, int]:
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        cwd=lcov.parent.parent,
        capture_output=True,
        text=True,
    )
    return result.stdout, result.stderr, result.returncode


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        lcov = make_lcov(Path(tmp))
        stdout, stderr, code = run_filter(lcov)

        if code != 0:
            print(f'filter_coverage.py exited with {code}: {stderr}', file=sys.stderr)
            return 1

        output = lcov.read_text()
        for excluded in [
            'lib/main.dart',
            'lib/pages/home.dart',
            'lib/widgets/glass.dart',
            'lib/pages/detail/widgets/detail_card.dart',
            'lib/core/services/download_service.g.dart',
        ]:
            if excluded in output:
                print(f'Excluded file {excluded} still present in lcov output', file=sys.stderr)
                return 1

        if 'lib/core/utils/platform.dart' not in output:
            print('Expected lib/core/utils/platform.dart to be kept', file=sys.stderr)
            return 1

        if 'Filtered coverage: 2/2 = 100%' not in stdout:
            print(f'Expected coverage summary not found: {stdout}', file=sys.stderr)
            return 1

    print('filter_coverage.py tests passed')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
