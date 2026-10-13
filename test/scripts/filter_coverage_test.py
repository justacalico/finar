import subprocess
import sys
import tempfile
from pathlib import Path

LCOV = """\
TN:
SF:lib/core/utils/formatters.dart
DA:1,1
DA:2,0
end_of_record
TN:
SF:lib/pages/home.dart
DA:1,1
end_of_record
TN:
SF:lib/l10n/generated/app_localizations.dart
DA:1,1
end_of_record
TN:
SF:lib/models/x.g.dart
DA:1,1
end_of_record
"""

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    (root / "coverage").mkdir()
    (root / "coverage/lcov.info").write_text(LCOV)
    result = subprocess.run(
        [sys.executable, str(Path(__file__).resolve().parents[2]
                             / "scripts/filter_coverage.py")],
        cwd=root, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    out = (root / "coverage/lcov.info").read_text()
    assert "formatters.dart" in out
    assert "home.dart" not in out
    assert "app_localizations" not in out
    assert "g.dart" not in out

print("ok filter_coverage")
