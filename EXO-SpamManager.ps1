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
    Version:        1.0.0
    Author:         Exchange Spam Manager Project
    Creation Date:  2025-12-22
    Purpose:        Automate Exchange Online spam filter management

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
  # Workaround for PackageManagement errors - force module load with all suppressions
  try {
    $savedErrorPref = $ErrorActionPreference
    $savedWarnPref = $WarningPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $WarningPreference = 'SilentlyContinue'

    Import-Module $Name -Force -DisableNameChecking -ErrorAction SilentlyContinue -WarningAction SilentlyContinue 2>$null 3>$null

    $ErrorActionPreference = $savedErrorPref
    $WarningPreference = $savedWarnPref
  } catch {
    # Silently ignore - module may have loaded despite errors
  }
  # Verify the module loaded by checking if Connect-ExchangeOnline exists
  if ($Name -eq 'ExchangeOnlineManagement' -and -not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
    throw "Failed to load $Name module. Please run 'Import-Module $Name' manually to diagnose the issue."
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
    Establishes connection to Exchange Online with modern authentication.
    Uses the user's default browser for OAuth login flow.
  #>

  Write-Progress -Activity 'Connecting' -Status 'Opening Exchange Online session...' -PercentComplete 5
  Ensure-Module -Name ExchangeOnlineManagement

  # Get user's default browser
  $browser = Get-DefaultBrowser

  if ($browser) {
    # Use detected browser with proper arguments
    $browserArgs = "{0} %s" -f $browser.Args
    Write-Info "Opening authentication in: $($browser.Name)"
    Write-Info "Please complete the login in your browser window..."

    try {
      Connect-ExchangeOnline -ShowBanner:$false -Device:$false | Out-Null
      Write-Info 'Exchange Online connection established successfully.'
    } catch {
      Write-Warning "Failed to connect with detected browser. Trying system default..."
      Connect-ExchangeOnline -ShowBanner:$false | Out-Null
      Write-Info 'Exchange Online connection established successfully.'
    }
  } else {
    # Use system default browser
    Write-Info "Opening authentication in your default browser..."
    Write-Info "Please complete the login in your browser window..."
    Connect-ExchangeOnline -ShowBanner:$false | Out-Null
    Write-Info 'Exchange Online connection established successfully.'
  }
}

function Read-Lines {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "TXT bulunamadı: $Path (Sadece bu dosya okunur; lütfen oluşturun ve tekrar deneyin.)"
  }
  $enc = [System.Text.UTF8Encoding]::new($false)
  return [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path), $enc)
}

# Basit kalıplar
$reEmail  = '^(?=.{3,254}$)[A-Za-z0-9_.+\-\'']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
$reDomain = '^(\*\.)?[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

function Classify {
  param([string[]]$Lines)
  $emails  = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
  $domains = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)

  $i = 0; $total = $Lines.Count
  foreach ($raw in $Lines) {
    $i++
    $pct = if ($total -gt 0) { [math]::Floor(($i/$total)*100) } else { 100 }
    Write-Progress -Activity 'TXT okunuyor' -Status "Satır işleniyor ($i/$total)" -PercentComplete $pct

    $line = ($raw -as [string]).Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.StartsWith('#') -or $line.StartsWith(';')) { continue }

    if ($line -match $reEmail) { [void]$emails.Add($line); continue }
    if (($line -match $reDomain) -and -not ($line -like '*@*')) {
      if ($line.StartsWith('*.')) { [void]$domains.Add($line.Substring(2)) } else { [void]$domains.Add($line) }
      continue
    }
  }

  # HashSet -> dizi (LINQ kullanmadan)
  $emailArr  = ($emails.GetEnumerator()  | ForEach-Object { $_ }) | Sort-Object -Unique
  $domainArr = ($domains.GetEnumerator() | ForEach-Object { $_ }) | Sort-Object -Unique

  [pscustomobject]@{
    Emails  = $emailArr
    Domains = $domainArr
  }
}

function Ensure-PolicyExists {
  param([string]$Name)
  Write-Progress -Activity 'Policy kontrol' -Status "Policy kontrol ediliyor: $Name" -PercentComplete 35
  $p = Get-HostedContentFilterPolicy -Identity $Name -ErrorAction SilentlyContinue
  if ($null -eq $p) { throw "Inbound anti-spam policy '$Name' bulunamadı. Lütfen önceden oluşturun." }
}

function Ensure-RuleForAllAcceptedDomains {
  param([string]$RuleName,[string]$PolicyName)
  Write-Progress -Activity 'Kapsam ayarlanıyor' -Status 'Accepted domainler alınıyor...' -PercentComplete 50

  # Tüm accepted domain’leri al; onmicrosoft’ı hariç tut
  $accepted = (Get-AcceptedDomain | Where-Object { -not $_.DomainName.EndsWith('.onmicrosoft.com') }).DomainName
  if (-not $accepted -or $accepted.Count -eq 0) { $accepted = (Get-AcceptedDomain).DomainName }
  $domains = $accepted | Sort-Object -Unique

  # Önce tam isimle kural aranıyor
  $r = Get-HostedContentFilterRule -Identity $RuleName -ErrorAction SilentlyContinue

  # Eğer tam isim bulunamadıysa, aynı policy ile ilişkili başka bir kural var mı diye kontrol et
  if ($null -eq $r) {
    $existingForPolicy = Get-HostedContentFilterRule -ErrorAction SilentlyContinue | Where-Object { $_.HostedContentFilterPolicy -eq $PolicyName } | Select-Object -First 1
    if ($existingForPolicy) {
      Write-Info "Policy '$PolicyName' zaten kural '$($existingForPolicy.Name)' ile ilişkilendirilmiş; mevcut kural güncellenecek."
      $r = $existingForPolicy
    }
  }

  if ($null -eq $r) {
    # Hiçbir ilgili kural yoksa yeni kural oluştur
    Write-Info "Inbound rule oluşturuluyor: $RuleName"
    New-HostedContentFilterRule -Name $RuleName -HostedContentFilterPolicy $PolicyName -RecipientDomainIs $domains -Enabled:$true | Out-Null
    return
  }

  # Mevcut kuralı gerektiği şekilde güncelle
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
  # 'Enabled' property may not exist on deserialized/older objects; kontrol etmeden erişmeyelim
  if ($null -ne $r.PSObject.Properties['Enabled']) {
    if (-not $r.Enabled) {
      Set-HostedContentFilterRule -Identity $identityToUse -Enabled:$true | Out-Null
      $changed = $true
    }
  } else {
    Write-Info "Kural '$identityToUse' nesnesinde 'Enabled' özelliği yok; Enabled ayarı atlanıyor."
  }
  if ($changed) { Write-Info 'Inbound rule güncellendi.' }
}

function Update-BlockedLists {
  param([string]$PolicyName,[string[]]$Emails,[string[]]$Domains,[switch]$RemoveMissing)
  Write-Progress -Activity 'Blok listeleri' -Status 'Mevcut değerler okunuyor...' -PercentComplete 65
  $policy = Get-HostedContentFilterPolicy -Identity $PolicyName

  # Mevcut değerleri düz string listesine çevir; API bazen obje dönebilir
  $currentEmails  = @($policy.BlockedSenders) | ForEach-Object { ($_ | Out-String).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  $currentDomains = @($policy.BlockedSenderDomains) | ForEach-Object { ($_ | Out-String).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

  # Ekleme set’leri — güvenli karşılaştırma (sadece düz stringler)
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
    Write-Progress -Activity 'Blok listeleri' -Status ("E‑posta ekleniyor ({0})" -f $toAddEmails.Count) -PercentComplete 75
    Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenders       @{ Add = $toAddEmails }
    Write-Info ("Eklendi (emails): {0}" -f $toAddEmails.Count)
  }
  if ($toAddDomains.Count -gt 0) {
    Write-Progress -Activity 'Blok listeleri' -Status ("Domain ekleniyor ({0})" -f $toAddDomains.Count) -PercentComplete 80
    Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenderDomains @{ Add = $toAddDomains }
    Write-Info ("Eklendi (domains): {0}" -f $toAddDomains.Count)
  }

  if ($RemoveMissing) {
    # Kaldırma set’leri — güvenli string karşılaştırma
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
      Write-Progress -Activity 'Blok listeleri' -Status ("E‑posta kaldırılıyor ({0})" -f $toRemoveEmails.Count) -PercentComplete 85
      Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenders       @{ Remove = $toRemoveEmails }
      Write-Info ("Kaldırıldı (emails): {0}" -f $toRemoveEmails.Count)
    }
    if ($toRemoveDomains.Count -gt 0) {
      Write-Progress -Activity 'Blok listeleri' -Status ("Domain kaldırılıyor ({0})" -f $toRemoveDomains.Count) -PercentComplete 90
      Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenderDomains @{ Remove = $toRemoveDomains }
      Write-Info ("Kaldırıldı (domains): {0}" -f $toRemoveDomains.Count)
    }
  }
}

# MAIN
try {
  Write-Info 'Başlatılıyor...'
  Connect-EXO

  Write-Info ("TXT dosyası: {0}" -f $BlockedTxtPath)
  $lines = Read-Lines -Path $BlockedTxtPath
  $data  = Classify -Lines $lines
  Write-Info ("Sınıflandırma: {0} e‑posta, {1} domain" -f $data.Emails.Count, $data.Domains.Count)

  Ensure-PolicyExists -Name $PolicyName
  Ensure-RuleForAllAcceptedDomains -RuleName $RuleName -PolicyName $PolicyName
  Update-BlockedLists -PolicyName $PolicyName -Emails $data.Emails -Domains $data.Domains -RemoveMissing:$RemoveMissing

  $p = Get-HostedContentFilterPolicy -Identity $PolicyName
  $r = Get-HostedContentFilterRule   -Identity $RuleName -ErrorAction SilentlyContinue
  Write-Progress -Activity 'Tamamlandı' -Completed
  Write-Host ''
  Write-Host 'ÖZET' -ForegroundColor Cyan
  Write-Host ('Policy        : {0}' -f $p.Name)
  Write-Host ('BlockedSenders: {0}' -f $p.BlockedSenders.Count)
  Write-Host ('BlockedDomains: {0}' -f $p.BlockedSenderDomains.Count)
  if ($r) { Write-Host ('Kapsam        : {0}' -f ($r.RecipientDomainIs -join ', ')) }
  Write-Info 'Bitti.'
}
catch {
  Write-Progress -Activity 'Hata' -Completed
  Write-Host "HATA DETAYI:" -ForegroundColor Red
  Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
  Write-Host "Type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
  Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}
finally {
  try { Disconnect-ExchangeOnline -Confirm:$false | Out-Null } catch {}
}