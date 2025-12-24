<#
.SYNOPSIS
    GUI Launcher for 365 Exo Spam List Editor

.DESCRIPTION
    Launches the GUI interface by calling the GUI-Interface module
#>

[CmdletBinding()]
param()

# Determine script root (handles both script and compiled EXE)
if ($PSScriptRoot) {
    $ScriptRoot = $PSScriptRoot
} else {
    # For compiled EXE, get the directory of the executable
    $ScriptRoot = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

# Import GUI module
. "$ScriptRoot\GUI-Interface.ps1"

# Start the GUI
Start-GUI
