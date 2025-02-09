from pathlib import Path
import shutil

CURRENT = Path(__file__).resolve().parent


def str_path(p: Path):
    s = str(p)
    return s.replace("\\", "/")


def file_read(p: Path):
    content = p.read_text(encoding="utf8")
    return content


def file_write(p: Path, content: str):
    p.write_text(content, encoding="utf8")


def fix_pyenv_cfg(venv_path: Path):
    cfg = venv_path.joinpath("pyvenv.cfg")

    c = file_read(cfg)
    c = c.replace(
        "include-system-site-packages = false", "include-system-site-packages = true"
    )
    file_write(cfg, c)


def create_shell_wrapper(venv_path: Path, force=False):
    fish_ps1 = CURRENT.joinpath("fish.ps1")
    bash_ps1 = CURRENT.joinpath("bash.ps1")

    def copy_impl(file: Path):
        target = venv_path.joinpath("bin").joinpath(file.name)
        if not force:
            if not target.exists():
                shutil.copy(file, target)
        else:
            if target.exists():
                target.unlink()
            shutil.copy(file, target)

    copy_impl(fish_ps1)
    copy_impl(bash_ps1)
    copy_impl(CURRENT.joinpath("pack_install.ps1"))
    copy_impl(CURRENT.joinpath("pack_remove.ps1"))

    fix_pyenv_cfg(venv_path)


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
