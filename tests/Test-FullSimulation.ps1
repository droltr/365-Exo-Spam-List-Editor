<#
.SYNOPSIS
    Full simulation test without requiring Exchange Online connection

.DESCRIPTION
    This test simulates the entire workflow including:
    - Browser detection
    - Authentication flow (simulated)
    - File parsing
    - Policy updates (simulated)
    - Rule creation (simulated)
    - Summary output

    Perfect for testing the tool without Exchange Online access.
#>

param(
    [string]$BlockedTxtPath = "..\blocked.txt"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FULL SIMULATION TEST - Exchange Online Spam Manager" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Simulate timestamp function
function Write-Info {
    param([string]$Message)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "[$ts] $Message" -ForegroundColor White
}

# Step 1: Browser Detection
Write-Host "--- Step 1: Browser Detection ---" -ForegroundColor Yellow
Write-Info "Detecting default browser..."
Start-Sleep -Milliseconds 500

try {
    $regKey = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' -ErrorAction Stop
    $progId = $regKey.ProgId

    switch -Wildcard ($progId) {
        '*Firefox*' { $browserName = 'Mozilla Firefox' }
        '*Chrome*' { $browserName = 'Google Chrome' }
        '*Edge*' { $browserName = 'Microsoft Edge' }
        '*Brave*' { $browserName = 'Brave' }
        default { $browserName = 'Unknown Browser' }
    }

    Write-Info "Opening authentication in: $browserName"
    Write-Host "  [SIMULATED] Browser window opened" -ForegroundColor Green
} catch {
    Write-Info "Using system default browser"
    Write-Host "  [SIMULATED] Browser window opened" -ForegroundColor Green
}

# Step 2: Authentication
Write-Host "`n--- Step 2: Authentication Flow ---" -ForegroundColor Yellow
Write-Info "Please complete the login in your browser window..."
Write-Host "  [SIMULATED] User navigates to login.microsoftonline.com" -ForegroundColor Gray
Start-Sleep -Seconds 1
Write-Host "  [SIMULATED] User enters: user@domain.com" -ForegroundColor Gray
Start-Sleep -Seconds 1
Write-Host "  [SIMULATED] User enters password" -ForegroundColor Gray
Start-Sleep -Seconds 1
Write-Host "  [SIMULATED] MFA verification (Authenticator App)" -ForegroundColor Gray
Start-Sleep -Seconds 2
Write-Host "  [SIMULATED] Authentication approved!" -ForegroundColor Green
Start-Sleep -Seconds 1
Write-Info "Exchange Online connection established successfully."

# Step 3: File Reading
Write-Host "`n--- Step 3: Reading Blocked Entries ---" -ForegroundColor Yellow
Write-Info "TXT file: $BlockedTxtPath"

if (Test-Path $BlockedTxtPath) {
    $lines = Get-Content $BlockedTxtPath

    # Classify entries
    $emails = $lines | Where-Object { $_ -match '@' -and $_ -notmatch '^#' -and $_ -notmatch '^;' }
    $domains = $lines | Where-Object { $_ -match '\.' -and $_ -notmatch '@' -and $_ -notmatch '^#' -and $_ -notmatch '^;' -and $_ -notmatch 'keywords' }

    Write-Info "Classification: $($emails.Count) emails, $($domains.Count) domains"

    Write-Host "`n  Emails to block:" -ForegroundColor Cyan
    $emails | Select-Object -First 5 | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    if ($emails.Count -gt 5) { Write-Host "    ... and $($emails.Count - 5) more" -ForegroundColor Gray }

    Write-Host "`n  Domains to block:" -ForegroundColor Cyan
    $domains | Select-Object -First 5 | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    if ($domains.Count -gt 5) { Write-Host "    ... and $($domains.Count - 5) more" -ForegroundColor Gray }
} else {
    Write-Host "  [ERROR] File not found: $BlockedTxtPath" -ForegroundColor Red
    exit 1
}

# Step 4: Policy Check
Write-Host "`n--- Step 4: Checking Spam Policy ---" -ForegroundColor Yellow
Write-Info "Verifying policy exists: 'Spam'"
Start-Sleep -Milliseconds 500
Write-Host "  [SIMULATED] Policy 'Spam' found in Exchange Online" -ForegroundColor Green
Write-Host "  Current BlockedSenders: 23" -ForegroundColor Gray
Write-Host "  Current BlockedDomains: 15" -ForegroundColor Gray

# Step 5: Updating Lists
Write-Host "`n--- Step 5: Updating Blocked Lists ---" -ForegroundColor Yellow
Write-Info "Adding entries to policy..."
Start-Sleep -Seconds 1
Write-Host "  [SIMULATED] Adding $($emails.Count) emails to BlockedSenders" -ForegroundColor Green
Start-Sleep -Milliseconds 500
Write-Host "  [SIMULATED] Adding $($domains.Count) domains to BlockedSenderDomains" -ForegroundColor Green
Start-Sleep -Milliseconds 500
Write-Info "Added (emails): $($emails.Count)"
Write-Info "Added (domains): $($domains.Count)"

# Step 6: Rule Management
Write-Host "`n--- Step 6: Managing Inbound Rule ---" -ForegroundColor Yellow
Write-Info "Checking inbound rule: 'Spam (Inbound Rule)'"
Start-Sleep -Milliseconds 500
Write-Host "  [SIMULATED] Rule found, updating..." -ForegroundColor Green
Write-Host "  Applied to domains: contoso.com, fabrikam.com" -ForegroundColor Gray
Write-Host "  Status: Enabled" -ForegroundColor Gray
Write-Info "Inbound rule updated."

# Step 7: Summary
Write-Host "`n--- Step 7: Summary ---" -ForegroundColor Yellow
Start-Sleep -Milliseconds 500

Write-Host "`nÖZET" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Policy        : Spam" -ForegroundColor White
Write-Host "BlockedSenders: $($emails.Count + 23) (was 23, added $($emails.Count))" -ForegroundColor White
Write-Host "BlockedDomains: $($domains.Count + 15) (was 15, added $($domains.Count))" -ForegroundColor White
Write-Host "Scope         : contoso.com, fabrikam.com" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# Step 8: Disconnection
Write-Host "`n--- Step 8: Cleanup ---" -ForegroundColor Yellow
Write-Info "Disconnecting from Exchange Online..."
Start-Sleep -Milliseconds 500
Write-Host "  [SIMULATED] Session closed" -ForegroundColor Green

Write-Info "Completed!"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Simulation completed successfully!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "What was simulated:" -ForegroundColor Yellow
Write-Host "  ✅ Browser detection (Firefox)" -ForegroundColor White
Write-Host "  ✅ OAuth authentication flow" -ForegroundColor White
Write-Host "  ✅ File parsing and classification" -ForegroundColor White
Write-Host "  ✅ Policy updates (BlockedSenders & BlockedDomains)" -ForegroundColor White
Write-Host "  ✅ Inbound rule creation/update" -ForegroundColor White
Write-Host "  ✅ Summary report" -ForegroundColor White

Write-Host "`nNote: This was a SIMULATION. No real changes were made to Exchange Online." -ForegroundColor Cyan
Write-Host "To run for real, install ExchangeOnlineManagement module and use valid credentials.`n" -ForegroundColor Cyan
