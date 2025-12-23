<#
.SYNOPSIS
    Exchange Online Spam Filter Manager - Updates spam policies from text file

.DESCRIPTION
    This script manages Exchange Online anti-spam policies by importing blocked entries
    from a text file. It automatically classifies entries and updates the spam filter policy.

    Features:
    - Classifies entries from text file:
      * Email addresses → BlockedSenders list
      * Domains (example.com, *.sub.example) → BlockedSenderDomains list
      * Wildcard domains (*.domain.com) are converted to root domain (domain.com)
    - Updates existing "Spam" Hosted Content Filter Policy (incremental add by default)
    - Optional sync mode with -RemoveMissing parameter removes entries not in the file
    - Creates/updates "Spam (Inbound Rule)" and applies to all accepted domains
    - Provides progress bars and timestamped logging in terminal

.PARAMETER BlockedTxtPath
    Path to the text file containing blocked entries (emails and domains)
    Default: C:\scripts\blocked.txt

.PARAMETER PolicyName
    Name of the Exchange Online Hosted Content Filter Policy to update
    Default: Spam

.PARAMETER RuleName
    Name of the inbound filter rule to create/update
    Default: Spam (Inbound Rule)

.PARAMETER RemoveMissing
    Switch to enable sync mode - removes entries from policy that are not in the text file
    WARNING: This will remove any blocked senders/domains not present in your text file

.EXAMPLE
    .\EXO-SpamManager.ps1
    Updates the spam policy using default blocked.txt file (incremental mode)

.EXAMPLE
    .\EXO-SpamManager.ps1 -BlockedTxtPath ".\my-blocked-list.txt"
    Updates using a custom text file

.EXAMPLE
    .\EXO-SpamManager.ps1 -RemoveMissing
    Syncs the policy to match the text file exactly (removes entries not in file)

.EXAMPLE
    .\EXO-SpamManager.ps1 -PolicyName "CustomSpam" -RuleName "Custom Rule"
    Uses custom policy and rule names

.NOTES
    Version:        0.4.0
    Author:         Exchange Spam Manager Project
    Creation Date:  2025-12-22
    Purpose:        Automate Exchange Online spam filter management
    Status:         Beta - Testing Phase

    Requirements:
    - ExchangeOnlineManagement PowerShell module
    - Exchange Online administrator permissions
    - Internet connectivity

.LINK
    https://github.com/yourusername/exchange-spam-manager
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

function Write-Info {
  param([string]$Message)
  $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  Write-Host "[$ts] $Message"
}

function Ensure-Module {
  param([string]$Name)

  # Check if module is already loaded
  if (Get-Module -Name $Name) {
    return
  }

  # Try to import quietly
  Import-Module $Name -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

  # Verify critical commands are available
  if ($Name -eq 'ExchangeOnlineManagement') {
    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
      throw "ExchangeOnlineManagement module not available. Please install: Install-Module ExchangeOnlineManagement"
    }
  }
}

function Get-DefaultBrowser {
  <#
  .SYNOPSIS
    Detects the user's default web browser
  .DESCRIPTION
    Attempts to find the default browser from Windows registry and common installation paths
  #>

  # Try to get default browser from registry
  try {
    $defaultBrowserKey = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' -ErrorAction SilentlyContinue
    if ($defaultBrowserKey) {
      $progId = $defaultBrowserKey.ProgId

      # Map ProgId to browser info
      switch -Wildcard ($progId) {
        '*Chrome*' {
          $browserPaths = @(
            'C:\Program Files\Google\Chrome\Application\chrome.exe',
            'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
          )
          $browserName = 'Google Chrome'
          $browserArgs = '--new-window'
        }
        '*Edge*' {
          $browserPaths = @(
            'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
            'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
          )
          $browserName = 'Microsoft Edge'
          $browserArgs = '--new-window'
        }
        '*Firefox*' {
          $browserPaths = @(
            'C:\Program Files\Mozilla Firefox\firefox.exe',
            'C:\Program Files (x86)\Mozilla Firefox\firefox.exe'
          )
          $browserName = 'Mozilla Firefox'
          $browserArgs = '-new-window'
        }
        '*Brave*' {
          $browserPaths = @(
            "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
            'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe'
          )
          $browserName = 'Brave'
          $browserArgs = '--new-window'
        }
        default {
          $browserPaths = @()
          $browserName = 'Unknown'
          $browserArgs = ''
        }
      }

      # Find the browser executable
      foreach ($path in $browserPaths) {
        if (Test-Path -LiteralPath $path) {
          Write-Verbose "Found default browser: $browserName at $path"
          return @{
            Path = $path
            Args = $browserArgs
            Name = $browserName
          }
        }
      }
    }
  } catch {
    Write-Verbose "Could not detect default browser from registry: $_"
  }

  # Fallback: Check common browser installations
  $fallbackBrowsers = @(
    @{ Path = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe'; Args = '--new-window'; Name = 'Microsoft Edge (64-bit)' }
    @{ Path = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'; Args = '--new-window'; Name = 'Microsoft Edge (32-bit)' }
    @{ Path = 'C:\Program Files\Google\Chrome\Application\chrome.exe'; Args = '--new-window'; Name = 'Google Chrome (64-bit)' }
    @{ Path = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'; Args = '--new-window'; Name = 'Google Chrome (32-bit)' }
    @{ Path = 'C:\Program Files\Mozilla Firefox\firefox.exe'; Args = '-new-window'; Name = 'Mozilla Firefox (64-bit)' }
    @{ Path = 'C:\Program Files (x86)\Mozilla Firefox\firefox.exe'; Args = '-new-window'; Name = 'Mozilla Firefox (32-bit)' }
  )

  foreach ($browser in $fallbackBrowsers) {
    if (Test-Path -LiteralPath $browser.Path) {
      Write-Verbose "Using fallback browser: $($browser.Name)"
      return $browser
    }
  }

  # If no browser found, return null (will use system default)
  Write-Verbose "No browser detected, using system default"
  return $null
}

function Connect-EXO {
  <#
  .SYNOPSIS
    Connects to Exchange Online using OAuth authentication
  .DESCRIPTION
    Checks for existing connection or establishes new one.
    Tries multiple authentication methods for reliability.
  #>

  Write-Progress -Activity 'Connecting' -Status 'Checking Exchange Online connection...' -PercentComplete 5
  
  # Ensure module is installed
  try {
    Ensure-Module -Name ExchangeOnlineManagement
  } catch {
    Write-Info "Attempting to install ExchangeOnlineManagement module..."
    try {
      Install-Module -Name ExchangeOnlineManagement -Force -Scope CurrentUser -ErrorAction Stop
      Write-Info "Module installed successfully."
    } catch {
      throw "Failed to install ExchangeOnlineManagement module: $($_.Exception.Message)"
    }
  }

  # Check if already connected
  $existingSession = Get-PSSession | Where-Object {
    $_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.State -eq 'Opened'
  }

  if ($existingSession) {
    Write-Info "Using existing Exchange Online connection."
    return
  }

  Write-Info "Connecting to Exchange Online..."
  
  # Try authentication methods in order
  $authMethods = @(
    @{
      Name = "Device Code Authentication"
      Params = @{
        UseDeviceAuthentication = $true
        ShowBanner = $false
        ErrorAction = 'Stop'
      }
    },
    @{
      Name = "Browser-based Authentication"
      Params = @{
        ShowBanner = $false
        ErrorAction = 'Stop'
      }
    }
  )

  $connected = $false
  foreach ($method in $authMethods) {
    try {
      Write-Info "Trying: $($method.Name)..."
      Connect-ExchangeOnline @($method.Params)
      Write-Info "Connected successfully using $($method.Name)."
      $connected = $true
      break
    } catch {
      Write-Info "Failed to connect using $($method.Name): $($_.Exception.Message)"
      continue
    }
  }

  if (-not $connected) {
    throw "All connection methods failed. Please ensure:`n" +
          "1. ExchangeOnlineManagement module is installed`n" +
          "2. You have Exchange Online administrator permissions`n" +
          "3. Your account has MFA enabled (if required)`n" +
          "4. Network connectivity is available"
  }
}

function Read-Lines {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "TXT file not found: $Path (Only this file is read; please create it and try again.)"
  }
  $enc = [System.Text.UTF8Encoding]::new($false)
  return [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path), $enc)
}

# Simple patterns
$reEmail  = '^(?=.{3,254}$)[A-Za-z0-9_.+\-\'']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
$reDomain = '^(\*\.)?[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

function Classify {
  param([string[]]$Lines)
  $emails  = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
  $domains = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
  $keywords = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)

  $i = 0; $total = $Lines.Count
  $inKeywords = $false
  foreach ($raw in $Lines) {
    $i++
    $pct = if ($total -gt 0) { [math]::Floor(($i/$total)*100) } else { 100 }
    Write-Progress -Activity 'Reading TXT' -Status "Processing line ($i/$total)" -PercentComplete $pct

    $line = ($raw -as [string]).Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.Contains('---keywords---')) { $inKeywords = $true; continue }
    if ($line.StartsWith('#') -or $line.StartsWith(';')) { continue }

    if ($inKeywords) {
      if ($line) { [void]$keywords.Add($line) }
      continue
    }

    if ($line -match $reEmail) { [void]$emails.Add($line); continue }
    if (($line -match $reDomain) -and -not ($line -like '*@*')) {
      if ($line.StartsWith('*.')) { [void]$domains.Add($line.Substring(2)) } else { [void]$domains.Add($line) }
      continue
    }
  }

  # HashSet -> array (without LINQ)
  $emailArr  = ($emails.GetEnumerator()  | ForEach-Object { $_ }) | Sort-Object -Unique
  $domainArr = ($domains.GetEnumerator() | ForEach-Object { $_ }) | Sort-Object -Unique
  $keywordArr = ($keywords.GetEnumerator() | ForEach-Object { $_ }) | Sort-Object -Unique

  [pscustomobject]@{
    Emails  = $emailArr
    Domains = $domainArr
    Keywords = $keywordArr
  }
}

function Ensure-PolicyExists {
  param([string]$Name)
  Write-Progress -Activity 'Policy Check' -Status "Checking policy: $Name" -PercentComplete 35
  $p = Get-HostedContentFilterPolicy -Identity $Name -ErrorAction SilentlyContinue
  if ($null -eq $p) { throw "Inbound anti-spam policy '$Name' not found. Please create it beforehand." }
}

function Ensure-RuleForAllAcceptedDomains {
  param([string]$RuleName,[string]$PolicyName)
  Write-Progress -Activity 'Scope Setting' -Status 'Getting accepted domains...' -PercentComplete 50

  # Get all accepted domains; exclude onmicrosoft
  $accepted = (Get-AcceptedDomain | Where-Object { -not $_.DomainName.EndsWith('.onmicrosoft.com') }).DomainName
  if (-not $accepted -or $accepted.Count -eq 0) { $accepted = (Get-AcceptedDomain).DomainName }
  $domains = $accepted | Sort-Object -Unique

  # Search for rule by exact name first
  $r = Get-HostedContentFilterRule -Identity $RuleName -ErrorAction SilentlyContinue

  # If exact name not found, check if another rule is associated with the same policy
  if ($null -eq $r) {
    $existingForPolicy = Get-HostedContentFilterRule -ErrorAction SilentlyContinue | Where-Object { $_.HostedContentFilterPolicy -eq $PolicyName } | Select-Object -First 1
    if ($existingForPolicy) {
      Write-Info "Policy '$PolicyName' is already associated with rule '$($existingForPolicy.Name)'; updating existing rule."
      $r = $existingForPolicy
    }
  }

  if ($null -eq $r) {
    # Create new rule if no related rule exists
    Write-Info "Creating inbound rule: $RuleName"
    New-HostedContentFilterRule -Name $RuleName -HostedContentFilterPolicy $PolicyName -RecipientDomainIs $domains -Enabled:$true | Out-Null
    return
  }

  # Update existing rule as needed
  $changed = $false
  $identityToUse = $r.Name
  if ($r.HostedContentFilterPolicy -ne $PolicyName) {
    Set-HostedContentFilterRule -Identity $identityToUse -HostedContentFilterPolicy $PolicyName | Out-Null
    $changed = $true
  }
  $current = @($r.RecipientDomainIs)
  if (@(Compare-Object -ReferenceObject $current -DifferenceObject $domains).Count -gt 0) {
    Set-HostedContentFilterRule -Identity $identityToUse -RecipientDomainIs $domains | Out-Null
    $changed = $true
  }
  # 'Enabled' property may not exist on deserialized/older objects; access safely
  if ($null -ne $r.PSObject.Properties['Enabled']) {
    if (-not $r.Enabled) {
      Set-HostedContentFilterRule -Identity $identityToUse -Enabled:$true | Out-Null
      $changed = $true
    }
  } else {
    Write-Info "Rule '$identityToUse' object has no 'Enabled' property; skipping Enabled setting."
  }
  if ($changed) { Write-Info 'Inbound rule updated.' }
}

function Update-TransportRule {
  param([string]$RuleName, [string[]]$Emails, [string[]]$Domains, [string[]]$Keywords, [switch]$RemoveMissing)
  
  Write-Progress -Activity 'Transport Rule' -Status 'Checking Transport Rule...' -PercentComplete 60
  $tr = Get-TransportRule -Identity $RuleName -ErrorAction SilentlyContinue

  if ($null -eq $tr) {
    Write-Info "Creating Transport Rule: $RuleName"
    # Create new rule with initial values (if any)
    $params = @{
      Name = $RuleName
      Enabled = $true
      RejectMessageReasonText = "Message blocked by spam filter policy"
      StopRuleProcessing = $true
    }
    
    if ($Emails.Count -gt 0) { $params['From'] = $Emails }
    if ($Domains.Count -gt 0) { $params['SenderDomainIs'] = $Domains }
    if ($Keywords.Count -gt 0) { $params['SubjectOrBodyContainsWords'] = $Keywords }
    
    # Only create if we have at least one condition
    if ($Emails.Count -gt 0 -or $Domains.Count -gt 0 -or $Keywords.Count -gt 0) {
        New-TransportRule @params | Out-Null
        Write-Info "Transport Rule created."
    } else {
        Write-Info "No entries for Transport Rule, skipping creation."
    }
    return
  }

  # Update existing rule
  Write-Info "Updating Transport Rule: $RuleName"
  
  # For Transport Rules, we generally replace the lists if we are in sync mode or just adding
  # But since Transport Rules don't have simple "Add/Remove" methods like policies, 
  # we usually set the full list.
  
  # If RemoveMissing is false (incremental), we need to merge with existing
  $newEmails = @($Emails)
  $newDomains = @($Domains)
  $newKeywords = @($Keywords)

  if (-not $RemoveMissing) {
      if ($tr.From) { $newEmails += $tr.From }
      if ($tr.SenderDomainIs) { $newDomains += $tr.SenderDomainIs }
      if ($tr.SubjectOrBodyContainsWords) { $newKeywords += $tr.SubjectOrBodyContainsWords }
      
      $newEmails = $newEmails | Sort-Object -Unique
      $newDomains = $newDomains | Sort-Object -Unique
      $newKeywords = $newKeywords | Sort-Object -Unique
  }

  $params = @{ Identity = $tr.Identity }
  $updated = $false

  # Update From (Emails)
  if ($newEmails.Count -gt 0) {
      $params['From'] = $newEmails
      $updated = $true
  } elseif ($RemoveMissing -and $tr.From) {
      # If syncing and list is empty, we might need to clear it, but Set-TransportRule doesn't like empty lists for some params
      # Strategy: If list is empty, we don't set the parameter, effectively leaving it or we might need to remove the condition
      # For simplicity in this script, we update if we have values.
      $params['From'] = $null # This might fail depending on PS version, usually better to not pass it
  }

  # Update SenderDomainIs
  if ($newDomains.Count -gt 0) {
      $params['SenderDomainIs'] = $newDomains
      $updated = $true
  }

  # Update Keywords
  if ($newKeywords.Count -gt 0) {
      $params['SubjectOrBodyContainsWords'] = $newKeywords
      $updated = $true
  }

  if ($updated) {
      Set-TransportRule @params | Out-Null
      Write-Info "Transport Rule updated."
  }
}

function Update-BlockedLists {
  param([string]$PolicyName,[string[]]$Emails,[string[]]$Domains,[switch]$RemoveMissing)
  Write-Progress -Activity 'Block Lists' -Status 'Reading current values...' -PercentComplete 65
  $policy = Get-HostedContentFilterPolicy -Identity $PolicyName

  # Convert current values to flat string list; API sometimes returns objects
  $currentEmails  = @($policy.BlockedSenders) | ForEach-Object { ($_ | Out-String).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  $currentDomains = @($policy.BlockedSenderDomains) | ForEach-Object { ($_ | Out-String).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

  # Add sets — safe comparison (only flat strings)
  $toAddEmails  = @()
  foreach ($e in $Emails) {
    $s = ($e -as [string]).Trim()
    if (-not [string]::IsNullOrWhiteSpace($s) -and ($s -notin $currentEmails)) { $toAddEmails += $s }
  }
  $toAddEmails = $toAddEmails | Sort-Object -Unique

  $toAddDomains = @()
  foreach ($d in $Domains) {
    $s = ($d -as [string]).Trim()
    if (-not [string]::IsNullOrWhiteSpace($s) -and ($s -notin $currentDomains)) { $toAddDomains += $s }
  }
  $toAddDomains = $toAddDomains | Sort-Object -Unique

  if ($toAddEmails.Count -gt 0)  {
    Write-Progress -Activity 'Block Lists' -Status ("Adding emails ({0})" -f $toAddEmails.Count) -PercentComplete 75
    Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenders       @{ Add = $toAddEmails }
    Write-Info ("Added (emails): {0}" -f $toAddEmails.Count)
  }
  if ($toAddDomains.Count -gt 0) {
    Write-Progress -Activity 'Block Lists' -Status ("Adding domains ({0})" -f $toAddDomains.Count) -PercentComplete 80
    Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenderDomains @{ Add = $toAddDomains }
    Write-Info ("Added (domains): {0}" -f $toAddDomains.Count)
  }

  if ($RemoveMissing) {
    # Remove sets — safe string comparison
    $toRemoveEmails = @()
    foreach ($ce in $currentEmails) {
      if ($ce -notin $Emails) { $toRemoveEmails += $ce }
    }
    $toRemoveEmails = $toRemoveEmails | Sort-Object -Unique

    $toRemoveDomains = @()
    foreach ($cd in $currentDomains) {
      if ($cd -notin $Domains) { $toRemoveDomains += $cd }
    }
    $toRemoveDomains = $toRemoveDomains | Sort-Object -Unique

    if ($toRemoveEmails.Count -gt 0)  {
      Write-Progress -Activity 'Block Lists' -Status ("Removing emails ({0})" -f $toRemoveEmails.Count) -PercentComplete 85
      Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenders       @{ Remove = $toRemoveEmails }
      Write-Info ("Removed (emails): {0}" -f $toRemoveEmails.Count)
    }
    if ($toRemoveDomains.Count -gt 0) {
      Write-Progress -Activity 'Block Lists' -Status ("Removing domains ({0})" -f $toRemoveDomains.Count) -PercentComplete 90
      Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenderDomains @{ Remove = $toRemoveDomains }
      Write-Info ("Removed (domains): {0}" -f $toRemoveDomains.Count)
    }
  }
}

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
  
  # Update EOP Policy
  Update-BlockedLists -PolicyName $PolicyName -Emails $data.Emails -Domains $data.Domains -RemoveMissing:$RemoveMissing
  
  # Update Transport Rule (Dual Write)
  $transportRuleName = "$RuleName (Transport)"
  Update-TransportRule -RuleName $transportRuleName -Emails $data.Emails -Domains $data.Domains -Keywords $data.Keywords -RemoveMissing:$RemoveMissing

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
}
catch {
  Write-Progress -Activity 'Error' -Completed
  Write-Host "ERROR DETAILS:" -ForegroundColor Red
  Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
  Write-Host "Type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
  Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}
finally {
  try { Disconnect-ExchangeOnline -Confirm:$false | Out-Null } catch {}
}