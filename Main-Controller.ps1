<#
.SYNOPSIS
    Main Controller for Exchange Online Spam Manager

.DESCRIPTION
    Orchestrates the entire spam management process by calling individual function modules
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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Import function modules
. "$PSScriptRoot\Common-Utils.ps1"
. "$PSScriptRoot\Connect-ExchangeOnline.ps1"
. "$PSScriptRoot\Get-Browser.ps1"
. "$PSScriptRoot\Parse-BlockedFile.ps1"
. "$PSScriptRoot\Update-EOPPolicy.ps1"
. "$PSScriptRoot\Update-TransportRule.ps1"

# MAIN
try {
  Write-Info 'Starting...'
  Connect-EXO

  Write-Info ("TXT file: {0}" -f $BlockedTxtPath)
  $lines = Read-Lines -Path $BlockedTxtPath
  $data  = Classify -Lines $lines
  Write-Info ("Classification: {0} emails, {1} domains, {2} keywords" -f $data.Emails.Count, $data.Domains.Count, $data.Keywords.Count)

  Ensure-PolicyExists -Name $PolicyName
  Ensure-RuleForAllAcceptedDomains -RuleName $RuleName -PolicyName $PolicyName

  # Update EOP Policy with error recovery
  try {
    Update-BlockedLists -PolicyName $PolicyName -Emails $data.Emails -Domains $data.Domains -RemoveMissing:$RemoveMissing
    Write-Info "EOP Policy updated successfully"
  } catch {
    Write-Warning "EOP Policy update failed: $($_.Exception.Message)"
    Write-Info "Continuing with Transport Rule update..."
  }

  # Update Transport Rule (Dual Write) with error recovery
  try {
    $transportRuleName = "$RuleName (Transport)"
    Update-TransportRule -RuleName $transportRuleName -Emails $data.Emails -Domains $data.Domains -Keywords $data.Keywords -RemoveMissing:$RemoveMissing
    Write-Info "Transport Rule updated successfully"
  } catch {
    Write-Warning "Transport Rule update failed: $($_.Exception.Message)"
    Write-Info "Continuing with summary..."
  }

  $p = Get-HostedContentFilterPolicy -Identity $PolicyName
  $r = Get-HostedContentFilterRule   -Identity $RuleName -ErrorAction SilentlyContinue
  $tr = Get-TransportRule -Identity $transportRuleName -ErrorAction SilentlyContinue

  Write-Progress -Activity 'Completed' -Completed
  Write-Host ''
  Write-Host 'SUMMARY' -ForegroundColor Cyan
  Write-Host ('Policy        : {0}' -f $p.Name)
  Write-Host ('BlockedSenders: {0}' -f $p.BlockedSenders.Count)
  Write-Host ('BlockedDomains: {0}' -f $p.BlockedSenderDomains.Count)
  if ($r) { Write-Host ('Scope         : {0}' -f ($r.RecipientDomainIs -join ', ')) }
  if ($tr) {
      Write-Host ('Transport Rule: {0}' -f $tr.Name)
      Write-Host ('  - Keywords  : {0}' -f ($tr.SubjectOrBodyContainsWords.Count))
  }
  Write-Info 'Done.'
  exit 0
}
catch {
  Write-Progress -Activity 'Error' -Completed
  Write-Host "ERROR DETAILS:" -ForegroundColor Red
  Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
  Write-Host "Type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
  Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
  
  # Detailed error logging
  $errorLog = @{
    Timestamp = Get-Date
    Message = $_.Exception.Message
    Type = $_.Exception.GetType().FullName
    StackTrace = $_.ScriptStackTrace
    Command = $_.InvocationInfo.MyCommand
    Line = $_.InvocationInfo.ScriptLineNumber
  }
  
  Write-Info "Detailed error logged for debugging"
  
  # Error recovery suggestions
  if ($_.Exception.Message -like "*Connect*") {
    Write-Host "SUGGESTION: Check your Exchange Online connection and permissions" -ForegroundColor Cyan
  } elseif ($_.Exception.Message -like "*Policy*") {
    Write-Host "SUGGESTION: Verify the spam filter policy exists and you have permissions" -ForegroundColor Cyan
  } elseif ($_.Exception.Message -like "*File*") {
    Write-Host "SUGGESTION: Check the blocked.txt file path and format" -ForegroundColor Cyan
  }
  
  exit 1
}
finally {
  try { Disconnect-EXO | Out-Null } catch {}
}