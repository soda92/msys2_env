from pathlib import Path
import subprocess
import argparse
import os
import shutil
import contextlib


@contextlib.contextmanager
def CD(d: Path):
    cwd = os.getcwd()
    os.chdir(d)
    yield
    os.chdir(cwd)


CURRENT = Path(__file__).resolve().parent
# ref: https://github.com/bleachbit/bleachbit/blob/master/windows/msys-install.ps1
cache_dir = Path.home().joinpath(".cache").joinpath("msys2_env")
rel_date = "2024-12-08"
rel_fn = "msys2-base-x86_64-20241208.sfx.exe"
release = cache_dir.joinpath(rel_date)


def download_msys():
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


def msys2_command(c, msys2_shell=f"{release}/msys64/msys2_shell.cmd"):
    commands = [
        msys2_shell,
        "-defterm",
        "-no-start",
        "-here",
        "-ucrt64",
        "-c",
    ]
    commands.append(c)
    subprocess.run(commands, check=True)


def venv_msys2_command(c, venv_path: Path):
    msys2_command(
        c,
        msys2_shell=venv_path.joinpath("data/msys2_shell.cmd"),
    )


def init():
    msys2_command("bash -c exit")
    install_packages()


def install_packages():
    msys2_command(
        "pacman -S --needed --noconfirm msys/fish ucrt64/mingw-w64-ucrt-x86_64-python"
    )


def venv_install_packages(venv_path: Path):
    venv_msys2_command(
        "pacman -S --needed --noconfirm msys/fish ucrt64/mingw-w64-ucrt-x86_64-python",
        venv_path=venv_path,
    )


def creat_py_venv(venv_path: Path):
    with CD(venv_path):
        venv_msys2_command("python -m venv .", venv_path=venv_path)


def init_wrapper(venv_path: Path):
    from msys2_env.shell_wrapper import create_scripts_alias, create_shell_wrapper

    create_scripts_alias(venv_path=venv_path)
    create_shell_wrapper(venv_path=venv_path)


def create_venv(venv_path: Path):
    if not venv_path.exists():
        venv_path.mkdir(parents=True)
        msys_folder = release.joinpath("msys64")

        shutil.copytree(msys_folder, venv_path.joinpath("data"))
    if not venv_path.joinpath("bin").exists():
        creat_py_venv(venv_path)
        init_wrapper(venv_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--init", action="store_true", default=False, help="download and init msys2"
    )

    parser.add_argument("--venv", type=str, default=".venv2", help="venv name")

    parser.add_argument(
        "--wrapper",
        action="store_true",
        default=False,
        help="reinstall the shell wrapper",
    )

    args = parser.parse_args()

    if args.init:
        download_msys()
        init()

    venv_path = Path(os.getcwd()).resolve().joinpath(args.venv)
    create_venv(venv_path)
    # venv_install_packages(venv_path)

    if args.wrapper:
        from msys2_env.shell_wrapper import create_scripts_alias, create_shell_wrapper

        create_scripts_alias(venv_path=venv_path, force=True)
        create_shell_wrapper(venv_path=venv_path, force=True)


if __name__ == "__main__":
    main()
