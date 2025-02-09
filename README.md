# msys2_env

<a href="https://pypi.org/project/msys2_env/">
    <img alt="PyPI - Version" src="https://img.shields.io/pypi/v/msys2_env">
</a>

Create python virtual environment using MSYS2.

## Install

```
pip install -U msys2_env
msys2_env --init
```

## usage

`msys2_env`: create a msys2 env in `venv`. the name can be specified via `--venv [name]`. The creation usually takes 3-5 minutes.

provide venv-like directory:

![tree directory](https://github.com/soda92/msys2_env/raw/main/image.png)

together with helper scripts:
- `.venv2/Scripts/Activate.ps1`: powershell activation script.
- `pack_install`: install msys2 packages.
- `pack_remove`: remove msys2 packages.
- `bash`: bash launcher.
- `fish`: fish launcher.


## command line help

```
msys2_env -h
usage: msys2_env [-h] [--init] [--venv VENV] [--wrapper]

options:
  -h, --help   show this help message and exit
  --init       download and init msys2
  --venv VENV  venv name
  --wrapper    reinstall the shell wrapper
```