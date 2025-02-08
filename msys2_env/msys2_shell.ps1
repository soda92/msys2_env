$Env:MSYSTEM = "ucrt64"

$root = Split-Path -Path $PSScriptRoot -Parent
& "$root/.venv3/data/usr/bin/fish.exe" -l
