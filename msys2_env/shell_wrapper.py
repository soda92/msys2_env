from pathlib import Path
import shutil

CURRENT = Path(__file__).resolve().parent


def str_path(p: Path):
    s = str(p)
    return s.replace("\\", "/")


def create_shell_wrapper(venv_path: Path, force=False):
    fish_ps1 = CURRENT.joinpath("fish.ps1")
    target = venv_path.joinpath(fish_ps1.name)
    if not force:
        if not target.exists():
            shutil.copy(fish_ps1, venv_path)
    else:
        if target.exists():
            target.unlink()
        shutil.copy(fish_ps1, venv_path)


def fix_content(scripts_dir: Path):
    script = scripts_dir.joinpath("Activate.ps1")
    content = script.read_text(encoding="utf8")
    original_script = scripts_dir.parent.joinpath("bin").joinpath("Activate.ps1")
    replacement = '"' + str_path(original_script) + '"'
    content = content.replace("$MyInvocation.MyCommand.Definition", replacement)
    script.write_text(content, encoding="utf8")


def create_scripts_alias(venv_path: Path, force=False):
    scripts_dir = venv_path.joinpath("Scripts")
    if not force:
        if not scripts_dir.exists():
            scripts_dir.mkdir()

            original_script = venv_path.joinpath("bin").joinpath("Activate.ps1")
            shutil.copy(original_script, scripts_dir)
    else:
        if scripts_dir.exists():
            shutil.rmtree(str_path(scripts_dir))
        scripts_dir.mkdir()

        original_script = venv_path.joinpath("bin").joinpath("Activate.ps1")
        shutil.copy(original_script, scripts_dir)

    fix_content(scripts_dir)
