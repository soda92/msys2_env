from pathlib import Path
import shutil

CURRENT = Path(__file__).resolve().parent


def create_shell_wrapper(venv_path: Path):
    fish_ps1 = CURRENT.joinpath("fish.ps1")
    target = venv_path.joinpath(fish_ps1.name)
    if not target.exists():
        shutil.copy(fish_ps1, venv_path)


def create_scripts_alias(venv_path: Path):
    scripts_dir = venv_path.joinpath("Scripts")
    if not scripts_dir.exists():
        scripts_dir.mkdir()

        original_script = venv_path.joinpath("bin").joinpath("Activate.ps1")
        shutil.copy(original_script, scripts_dir)
