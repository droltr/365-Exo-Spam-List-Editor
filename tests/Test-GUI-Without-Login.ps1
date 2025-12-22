<#
.SYNOPSIS
    Test script to demonstrate GUI without actual Exchange Online connection
.DESCRIPTION
    This script simulates the spam manager operations without connecting to Exchange Online.
    Useful for testing the GUI interface without valid credentials.
#>

[CmdletBinding()]
param(
    [string]$BlockedTxtPath = '.\blocked.txt'
)

# Simulate the operations
Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting simulation..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Simulating Exchange Online connection..." -ForegroundColor Yellow
Write-Host "NOTE: In real scenario, browser would open here for OAuth login" -ForegroundColor Magenta
Start-Sleep -Seconds 2

Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Reading blocked.txt..." -ForegroundColor Green

if (Test-Path $BlockedTxtPath) {
    $lines = Get-Content $BlockedTxtPath
    $emails = $lines | Where-Object { $_ -match '@' -and $_ -notmatch '^#' -and $_ -notmatch '^;' }
    $domains = $lines | Where-Object { $_ -match '\.' -and $_ -notmatch '@' -and $_ -notmatch '^#' -and $_ -notmatch '^;' }

    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Classification: $($emails.Count) emails, $($domains.Count) domains" -ForegroundColor Green

    Start-Sleep -Seconds 1

    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Simulating policy update..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2

    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Simulating rule creation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1

    Write-Host ""
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Policy        : Spam (simulated)" -ForegroundColor White
    Write-Host "BlockedSenders: $($emails.Count) (simulated)" -ForegroundColor White
    Write-Host "BlockedDomains: $($domains.Count) (simulated)" -ForegroundColor White
    Write-Host "Status        : SUCCESS (simulation)" -ForegroundColor Green
    Write-Host ""
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Simulation completed!" -ForegroundColor Green
} else {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: File not found: $BlockedTxtPath" -ForegroundColor Red
    throw "File not found: $BlockedTxtPath"
}
