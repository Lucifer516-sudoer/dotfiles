from .constants import SNAPSHOTS_DIR


def get_available_snapshots(aur: bool = False):
    SNAPSHOTS_DIR.absolute()
