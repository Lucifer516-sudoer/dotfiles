from pathlib import Path

ROOT_DIR: Path = Path(__file__).parent.parent
LOGS_DIR: Path = ROOT_DIR / "installer-logs-dir"
SNAPSHOTS_DIR: Path = ROOT_DIR / "Snapshots"
OFFICIAL_PACKAGES = "package-list.txt"
AUR_PACKAGES = "aur-package-list.txt"

LOGS_DIR.mkdir(parents=True, exist_ok=True)
SNAPSHOTS_DIR.mkdir(parents=True, exist_ok=True)
