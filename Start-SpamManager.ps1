<#
.SYNOPSIS
    GUI Launcher for Exchange Online Spam Manager

.DESCRIPTION
    Launches the GUI interface by calling the GUI-Interface module
#>

[CmdletBinding()]
param()

# Import GUI module
. "$PSScriptRoot\GUI-Interface.ps1"

# Start the GUI
Start-GUI
