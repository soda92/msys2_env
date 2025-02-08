from pathlib import Path
import subprocess
import argparse
import os
import shutil

CURRENT = Path(__file__).resolve().parent
cache_dir = Path.home().joinpath(".cache").joinpath("msys2_env")
rel_date = "2024-12-08"
rel_fn = "msys2-base-x86_64-20241208.sfx.exe"
release = cache_dir.joinpath(rel_date)


def download_msys():
    # ref: https://github.com/bleachbit/bleachbit/blob/master/windows/msys-install.ps1
    url = f"https://github.com/msys2/msys2-installer/releases/download/{rel_date}/{rel_fn}"

    cache_dir.mkdir(exist_ok=True, parents=True)

    release_file = cache_dir.joinpath(rel_fn)
    wget_file = CURRENT.joinpath("wget.exe")
    if not release.exists():
        subprocess.run([wget_file, url, "-O", release_file], check=True)
        subprocess.run(
            [
                release_file,
                "-y",
                f"-O{release}",
            ],
            check=True,
        )


def init():
    msys2_shell = f"{release}/msys64/msys2_shell.cmd"

    def msys2_command(c):
        msys2_base_command = [
            msys2_shell,
            "-defterm",
            "-no-start",
            "-here",
            "-ucrt64",
            "-c",
        ]
        msys2_base_command.append(c)
        ret = msys2_base_command
        return ret

    subprocess.run(msys2_command("bash -c exit"), check=True)


def create_venv(name: str):
    cwd = os.getcwd()
    venv_path = Path(cwd).resolve().joinpath(name)
    if venv_path.exists():
        # print("Err: venv already exists")
        exit()
    venv_path.mkdir(parents=True)
    msys_folder = release.joinpath("msys64")

    shutil.copytree(msys_folder, venv_path.joinpath("data"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--init", action="store_true", default=False, help="download and init msys2"
    )

    parser.add_argument("--venv", type=str, default=".venv2", help="venv name")

    args = parser.parse_args()

    if args.init:
        download_msys()
        init()

    create_venv(args.venv)


if __name__ == "__main__":
    main()
