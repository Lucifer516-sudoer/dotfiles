import re
import subprocess
from subprocess import CompletedProcess
from typing import Any


def run_cmd(command_string: str, **kwargs: Any) -> CompletedProcess[Any]:
    pattern = r'"([^"]*)"|\'([^\']*)\'|(\S+)'

    raw_matches = re.findall(pattern, command_string)

    parsed_list = [next(item for item in match if item) for match in raw_matches]

    return subprocess.run(parsed_list, **kwargs)  # type: ignore
