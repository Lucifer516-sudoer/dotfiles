import os
from pathlib import Path
from subprocess import CompletedProcess
from typing import Any, Generator

from .constants import ROOT_DIR
from .run_command import run_cmd


class FolderNotFound(Exception): ...


def lookout_for_the_folder(name: str) -> Path:
    contents = list((ROOT_DIR / each) for each in os.listdir(ROOT_DIR))

    if ROOT_DIR / name in contents and (ROOT_DIR / name).is_dir():
        return ROOT_DIR / name
    else:
        raise FolderNotFound("Folder not found")


def stow_the_folder(
    package_name: str, target_dir: Path | str = Path.home()
) -> CompletedProcess[Any] | None:
    target_dir = Path(target_dir).absolute().resolve()
    folder = lookout_for_the_folder(package_name)
    if folder:
        return run_cmd(
            f"stow --target={target_dir} {package_name} --verbose 1",
            cwd=ROOT_DIR,
        )


def available_stows() -> Generator[str, None, None]:
    for each in os.listdir(ROOT_DIR):
        if (ROOT_DIR / each).is_dir():
            yield each
