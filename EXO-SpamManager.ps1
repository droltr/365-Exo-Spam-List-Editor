<#
.SYNOPSIS
    CLI Launcher for Exchange Online Spam Manager

.DESCRIPTION
    Launches the CLI interface by calling the Main-Controller module
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$false, HelpMessage="Path to the text file containing blocked entries")]
  [ValidateNotNullOrEmpty()]
  [string]$BlockedTxtPath = '.\blocked.txt',

  [Parameter(Mandatory=$false, HelpMessage="Name of the spam filter policy")]
  [ValidateNotNullOrEmpty()]
  [string]$PolicyName = 'Spam',

  [Parameter(Mandatory=$false, HelpMessage="Name of the inbound filter rule")]
  [ValidateNotNullOrEmpty()]
  [string]$RuleName = 'Spam (Inbound Rule)',

  [Parameter(Mandatory=$false, HelpMessage="Enable sync mode to remove entries not in file")]
  [switch]$RemoveMissing
)

# Import main controller
. "$PSScriptRoot\Main-Controller.ps1"
