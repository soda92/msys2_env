import contextlib
from typing import Any
import subprocess  # noqa: F401
import shutil  # noqa: F401

from hatchling.builders.hooks.plugin.interface import BuildHookInterface


@contextlib.contextmanager
def CD(d: str):
    import os

    old = os.getcwd()
    os.chdir(d)
    yield
    os.chdir(old)


def build():
    pass

class CustomBuilder(BuildHookInterface):
    def initialize(
        self,
        version: str,  # noqa: ARG002
        build_data: dict[str, Any],
    ) -> None:
        build_data["tag"] = "py3-none-win_amd64"
        if self.target_name == "sdist":
            return
        build()


if __name__ == "__main__":
    build()
