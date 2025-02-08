# convert %~dp0

$p = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host $p
