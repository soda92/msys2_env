# Requires PSv5 or later for -WindowStyle

# Helper function to print help
function Print_Help {
    param (
        [string]$ScriptName
    )

    Write-Host "Usage:"
    Write-Host "    $ScriptName [options] [login shell parameters]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "    -mingw32 | -mingw64 | -ucrt64 | -clang32 | -clang64 |"
    Write-Host "    -msys[2] | -clangarm64             Set shell type"
    Write-Host "    -defterm | -mintty | -conemu       Set terminal type"
    Write-Host "    -here                             Use current directory as working"
    Write-Host "                                      directory"
    Write-Host "    -where DIRECTORY                   Use specified DIRECTORY as working"
    Write-Host "                                      directory"
    Write-Host "    -[use-]full-path                 Use full current PATH variable"
    Write-Host "                                      instead of trimming to minimal"
    Write-Host "    -no-start                         Do not use `"start`" command and"
    Write-Host "                                      return login shell resulting "
    Write-Host "                                      errorcode as this script's"
    Write-Host "                                      resulting errorcode"
    Write-Host "    -shell SHELL                     Set login shell"
    Write-Host "    -help | --help | -? | /?          Display this help and exit"
    Write-Host ""
    Write-Host "Any parameter that cannot be treated as valid option and all"
    Write-Host "following parameters are passed as login shell command parameters."
    Write-Host ""

    exit 0
}


# Helper Function to remove quotes from a string
function Remove-Quotes {
    param(
        [string]$InputString
    )
    return $InputString -replace '"', ''
}

# Helper function for ConEmu detection
function Detect_ConEmu {
    $ComEmuCommand = $null
    $MSYSCON = $null

    if ($env:ConEmuDir) {
        if (Test-Path "$($env:ConEmuDir)\ConEmu64.exe") {
            $ComEmuCommand = "$($env:ConEmuDir)\ConEmu64.exe"
            $MSYSCON = "conemu64.exe"
        }
        elseif (Test-Path "$($env:ConEmuDir)\ConEmu.exe") {
            $ComEmuCommand = "$($env:ConEmuDir)\ConEmu.exe"
            $MSYSCON = "conemu.exe"
        }
    }

    if (-not $ComEmuCommand) {
        if ($(ConEmu64.exe /Exit 2>&1) -match "ConEmu" ) {
            # Crude test, but checks if the command *exists*.
            $ComEmuCommand = "ConEmu64.exe"
            $MSYSCON = "conemu64.exe"
        }
        elseif ($(ConEmu.exe /Exit 2>&1) -match "ConEmu") {
            $ComEmuCommand = "ConEmu.exe"
            $MSYSCON = "conemu.exe"
        }
    }

    if (-not $ComEmuCommand) {
        $regEntry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ConEmu64.exe" -Name "(default)" -ErrorAction SilentlyContinue
        if ($regEntry) {
            $ComEmuCommand = $regEntry."(default)"
            $MSYSCON = "conemu64.exe"
        }
        else {
            $regEntry = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ConEmu.exe" -Name "(default)" -ErrorAction SilentlyContinue
            if ($regEntry) {
                $ComEmuCommand = $regEntry."(default)"
                $MSYSCON = "conemu.exe"
            }

        }
    }

    if (-not $ComEmuCommand) {
        Write-Error "ConEmu not found."
        exit 1
    }

    return @{
        Command = $ComEmuCommand
        MSYSCON = $MSYSCON
    }
}

function startsh() {
    if (-not $MSYS2_NOSTART) {
        Start-Process -FilePath "$WD\$LOGINSHELL" -ArgumentList "-l $shellArgsString" -WindowStyle Minimized
    }
    else {
        & "$WD\$LOGINSHELL" -l $shellArgsString
    }
    exit $LASTEXITCODE
}

# Main script logic

$WD = $PWD.Path
if (-not (Test-Path -Path "$WD\msys-2.0.dll")) {
    $WD = "$($PSScriptRoot)\usr\bin\"  # Use script's directory if msys-2.0.dll is missing.
}
$LOGINSHELL = "bash"
$msys2_shiftCounter = 0
$MSYS2_PATH_TYPE = $null  #  Keep it undefined initially
$CHERE_INVOKING = $null # Keep undefined initially
$MSYS2_NOSTART = $false  # Default is to *use* start.
$SHELL_ARGS = @()

# Parse command-line arguments
$argsList = $args

$i = 0
while ($i -lt $argsList.Count) {
    $arg = $argsList[$i]

    switch ($arg) {
        { "-help" -or "--help" -or "-?" -or "/?" } {
            Print_Help $MyInvocation.MyCommand.Name
            exit 0
        }
        { "-msys" -or "-msys2" } {
            $MSYSTEM = "MSYS"
            $msys2_shiftCounter++
        }
       { "-mingw32" } {
            $MSYSTEM = "MINGW32"
            $msys2_shiftCounter++
        }
       { "-mingw64" } {
            $MSYSTEM = "MINGW64"
            $msys2_shiftCounter++
        }
       { "-ucrt64" } {
            $MSYSTEM = "UCRT64"
            $msys2_shiftCounter++
        }
       { "-clang64" } {
            $MSYSTEM = "CLANG64"
            $msys2_shiftCounter++
        }
       { "-clang32" } {
            $MSYSTEM = "CLANG32"
            $msys2_shiftCounter++
        }
       { "-clangarm64" } {
            $MSYSTEM = "CLANGARM64"
            $msys2_shiftCounter++
        }
       { "-mingw" } {
            $msys2_shiftCounter++
            if (Test-Path "$WD\..\..\mingw64") {
                $MSYSTEM = "MINGW64"
            }
            else {
                $MSYSTEM = "MINGW32"
            }
        }
       { "-mintty" } {
            $MSYSCON = "mintty.exe"
            $msys2_shiftCounter++
        }
        { "-conemu" } {
            $MSYSCON = "conemu"  # We'll refine this in Detect_ConEmu
            $msys2_shiftCounter++
        }
        { "-defterm" } {
            $MSYSCON = "defterm"
            $msys2_shiftCounter++
        }
        { "-full-path" -or "-use-full-path" } {
            $MSYS2_PATH_TYPE = "inherit"
            $msys2_shiftCounter++
        }
        { "-here" } {
            $CHERE_INVOKING = "enabled_from_arguments"
            $msys2_shiftCounter++
        }
        { "-where" } {
            $i++
            if ($i -ge $argsList.Count -or [string]::IsNullOrWhiteSpace($argsList[$i])) {
                Write-Error "Working directory is not specified for -where parameter."
                exit 2
            }
            $targetDir = $argsList[$i]

            if (-not (Test-Path -Path $targetDir)) {
                Write-Error "Cannot set specified working directory '$targetDir'."
                exit 2
            }
            Set-Location -Path $targetDir
            $WD = $PWD.Path  # Update $WD
            $CHERE_INVOKING = "enabled_from_arguments"
            $msys2_shiftCounter += 2  # -where and the directory
        }
        { "-no-start" } {
            $MSYS2_NOSTART = $true
            $msys2_shiftCounter++
        }
        { "-shell" } {
            $i++
            if ($i -ge $argsList.Count -or [string]::IsNullOrWhiteSpace($argsList[$i])) {
                Write-Error "Shell not specified for -shell parameter."
                exit 2
            }
            $LOGINSHELL = Remove-Quotes $argsList[$i]
            $msys2_shiftCounter += 2
        }
        Default {
            # Collect remaining args
            break; # Stop processing options, the rest are shell arguments.

        }
    }
    $i++
}

# Collect remaining arguments for the shell
for ($j = $i; $j -lt $argsList.Count; $j++) {
    $SHELL_ARGS += $argsList[$j]
}


# Set title and icon
if ($MSYSTEM -eq "MINGW32") {
    $CONTITLE = "MinGW x32"
    $CONICON = "mingw32.ico"
}
elseif ($MSYSTEM -eq "MINGW64") {
    $CONTITLE = "MinGW x64"
    $CONICON = "mingw64.ico"
}
elseif ($MSYSTEM -eq "UCRT64") {
    $CONTITLE = "MinGW UCRT x64"
    $CONICON = "ucrt64.ico"
}
elseif ($MSYSTEM -eq "CLANG64") {
    $CONTITLE = "MinGW Clang x64"
    $CONICON = "clang64.ico"
}
elseif ($MSYSTEM -eq "CLANG32") {
    $CONTITLE = "MinGW Clang x32"
    $CONICON = "clang32.ico"
}
elseif ($MSYSTEM -eq "CLANGARM64") {
    $CONTITLE = "MinGW Clang ARM64"
    $CONICON = "clangarm64.ico"
}
else {
    $CONTITLE = "MSYS2 MSYS"
    $CONICON = "msys2.ico"
}


# Handle terminal selection and execution
$shellArgsString = [string]::Join(" ", ($SHELL_ARGS | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } })) # Quote args with spaces

if ($MSYSCON -eq "mintty.exe") {
    if (-not (Test-Path -Path "$WD\mintty.exe")) {
        Write-Warning "mintty.exe not found, falling back to default shell."
        startsh
    }

    if (-not $MSYS2_NOSTART) {
        Start-Process -FilePath "$WD\mintty" -ArgumentList "-i `"/$CONICON`"", "-t `"$CONTITLE`"", `"/usr/bin/$LOGINSHELL`" -l $shellArgsString -WindowStyle Minimized
    }
    else {
        & "$WD\mintty" -i "/$CONICON" -t "$CONTITLE" "/usr/bin/$LOGINSHELL" -l $shellArgsString
    }
    exit $LASTEXITCODE
}

if ($MSYSCON -eq "conemu") {
    $conEmuInfo = Detect_ConEmu
    $ComEmuCommand = $conEmuInfo.Command
    $MSYSCON = $conEmuInfo.MSYSCON

    if (-not $MSYS2_NOSTART) {
        Start-Process -FilePath $ComEmuCommand -ArgumentList "/Here", "/Icon `"$WD\..\..\$CONICON`", "/cmd `"$WD\$LOGINSHELL`" -l $shellArgsString  -WindowStyle Minimized
    }
    else {
        & $ComEmuCommand /Here /Icon "$WD\..\..\$CONICON" /cmd "$WD\$LOGINSHELL" -l $shellArgsString
    }
    exit $LASTEXITCODE
}
