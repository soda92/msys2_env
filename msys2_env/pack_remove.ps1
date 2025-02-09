$command = "pacman -Rs "
$list = @()
foreach ($arg in $args) {
    $c = "mingw-w64-ucrt-x86_64-" + $arg
    $list += $c
}

$command += $list -join " "

& "$PSScriptRoot/fish.ps1" -c $command
