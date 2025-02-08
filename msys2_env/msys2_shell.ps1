# Set working directory
$WD = Get-Location
if (!(Test-Path "$WD\msys-2.0.dll")) { $WD = Split-Path -parent $MyInvocation.MyCommand.Definition + "\usr\bin\" }
$LOGINSHELL = "bash"
$msys2_shiftCounter = 0

# To activate windows native symlinks uncomment next line
# $env:MSYS = "winsymlinks:nativestrict"

# Set debugging program for errors
# $env:MSYS = "error_start:$WD\../../mingw64/bin/qtcreator.exe^|-debug^|^<process-id^>"

# To export full current PATH from environment into MSYS2 use '-use-full-path' parameter
# or uncomment next line
# $env:MSYS2_PATH_TYPE = "inherit"

# Function to print help
function Print_Help {
    param([string]$ScriptName)
    Write-Host "Usage:"
    Write-Host "    $ScriptName [options] [login shell parameters]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "    -mingw32 | -mingw64 | -ucrt64 | -clang32 | -clang64 |"
    Write-Host "    -msys[2] | -clangarm64                   Set shell type"
    Write-Host "    -defterm | -mintty | -conemu            Set terminal type"
    Write-Host "    -here                                    Use current directory as working"
    Write-Host "                                            directory"
    Write-Host "    -where DIRECTORY                        Use specified DIRECTORY as working"
    Write-Host "                                            directory"
    Write-Host "    -[use-]full-path                        Use full current PATH variable"
    Write-Host "                                            instead of trimming to minimal"
    Write-Host "    -no-start                                Do not use 'start' command and"
    Write-Host "                                            return login shell resulting"
    Write-Host "                                            errorcode as this script"
    Write-Host "                                            resulting errorcode"
    Write-Host "    -shell SHELL                            Set login shell"
    Write-Host "    -help | --help | -? | /?                 Display this help and exit"
    Write-Host ""
    Write-Host "Any parameter that cannot be treated as valid option and all"
    Write-Host "following parameters are passed as login shell command parameters."
}

# Process command-line arguments

$Arguments = $args

foreach ($arg in $Arguments) {
    switch -Wildcard ($arg) {
        "-help" { Print-Help $MyInvocation.MyCommand.MyCommand.Name; exit 0 }
        "--help" { Print-Help $MyInvocation.MyCommand.MyCommand.Name; exit 0 }
        "-?" { Print-Help $MyInvocation.MyCommand.MyCommand.Name; exit 0 }
        "/?" { Print-Help $MyInvocation.MyCommand.MyCommand.Name; exit 0 }
        "-msys" { $msys2_shiftCounter++; $env:MSYSTEM = "MSYS"; }
        "-msys2" { $msys2_shiftCounter++; $env:MSYSTEM = "MSYS"; }
        "-mingw32" { $msys2_shiftCounter++; $env:MSYSTEM = "MINGW32"; }
        "-mingw64" { $msys2_shiftCounter++; $env:MSYSTEM = "MINGW64"; }
        "-ucrt64" { $msys2_shiftCounter++; $env:MSYSTEM = "UCRT64"; }
        "-clang64" { $msys2_shiftCounter++; $env:MSYSTEM = "CLANG64"; }
        "-clang32" { $msys2_shiftCounter++; $env:MSYSTEM = "CLANG32"; }
        "-clangarm64" { $msys2_shiftCounter++; $env:MSYSTEM = "CLANGARM64"; }
        "-mingw" { $msys2_shiftCounter++; if (Test-Path "$WD\..\..\mingw64") { $env:MSYSTEM = "MINGW64" } else { $env:MSYSTEM = "MINGW32" } }
        "-mintty" { $msys2_shiftCounter++; $env:MSYSCON = "mintty.exe"; }
        "-conemu" { $msys2_shiftCounter++; $env:MSYSCON = "conemu"; }
        "-defterm" { $msys2_shiftCounter++; $env:MSYSCON = "defterm"; }
        "-full-path" { $msys2_shiftCounter++; $env:MSYS2_PATH_TYPE = "inherit"; }
        "-use-full-path" { $msys2_shiftCounter++; $env:MSYS2_PATH_TYPE = "inherit"; }
        "-here" { $msys2_shiftCounter++; $env:CHERE_INVOKING = "enabled_from_arguments"; }
        "-where" {
            $msys2_shiftCounter++;
            if ($Arguments[$Arguments.IndexOf($arg) + 1]) {
                # Check for next argument
                $dir = $Arguments[$Arguments.IndexOf($arg) + 1]
                if (Test-Path $dir) {
                    Set-Location -Path $dir
                    $env:CHERE_INVOKING = "enabled_from_arguments"
                    $msys2_shiftCounter++ # Increment for the directory argument
                }
                else {
                    Write-Error "Cannot set specified working directory '$dir'."
                    exit 2
                }
            }
            else {
                Write-Error "Working directory is not specified for -where parameter."
                exit 2
            }
            # Remove the processed -where and directory arguments
            $Arguments = $Arguments | Where-Object { $_ -ne $arg -and $_ -ne $dir }
            continue  # Skip to the next argument
        }
        "-no-start" { $msys2_shiftCounter++; $env:MSYS2_NOSTART = "yes"; }
        "-shell" {
            $msys2_shiftCounter++;
            if ($Arguments[$Arguments.IndexOf($arg) + 1]) {
                $LOGINSHELL = $args[$Arguments.IndexOf($arg) + 1]
                $msys2_shiftCounter++ # Increment for the shell argument
            }
            else {
                Write-Error "Shell not specified for -shell parameter."
                exit 2
            }
            # Remove the -shell and shell arguments
            $Arguments = $Arguments | Where-Object { $_ -ne $arg -and $_ -ne $LOGINSHELL }
            continue  # Skip to the next argument
        }
        default { $remainingArgs += $arg } # Collect remaining arguments
    }
}


# ... (rest of the script - setting title, icon, starting shells)

# Setup proper title and icon
if ($env:MSYSTEM -eq "MINGW32") {
    $CONTITLE = "MinGW x32"
    $CONICON = "mingw32.ico"
}
elseif ($env:MSYSTEM -eq "MINGW64") {
    $CONTITLE = "MinGW x64"
    $CONICON = "mingw64.ico"
}
elseif ($env:MSYSTEM -eq "UCRT64") {
    $CONTITLE = "MinGW UCRT x64"
    $CONICON = "ucrt64.ico"
}
elseif ($env:MSYSTEM -eq "CLANG64") {
    $CONTITLE = "MinGW Clang x64"
    $CONICON = "clang64.ico"
}
elseif ($env:MSYSTEM -eq "CLANG32") {
    $CONTITLE = "MinGW Clang x32"
    $CONICON = "clang32.ico"
}
elseif ($env:MSYSTEM -eq "CLANGARM64") {
    $CONTITLE = "MinGW Clang ARM64"
    $CONICON = "clangarm64.ico"
}
else {
    $CONTITLE = "MSYS2 MSYS"
    $CONICON = "msys2.ico"
}

# ... (startmintty, startconemu, startsh logic - largely the same, but use PowerShell's start-process)

if ($env:MSYSCON -eq "mintty.exe") {
    # ... (startmintty logic)
}
elseif ($env:MSYSCON -eq "conemu") {
    # ... (startconemu logic)
}
else {
    # ... (startsh logic)
}



# ... (conemudetect function - convert registry queries to PowerShell's Get-ItemPropertyValue)

function ConEmuDetect {
    # ... (ConEmu detection logic using Get-ItemPropertyValue)
}

# ... (rest of the script)