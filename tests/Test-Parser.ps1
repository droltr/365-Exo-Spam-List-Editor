<#
.SYNOPSIS
    Test script for blocked entries file parsing

.DESCRIPTION
    Tests the classification logic from EXO-SpamManager.ps1
    Validates that emails and domains are correctly identified
#>

param(
    [string]$TestFile = ".\test-blocked.txt"
)

Write-Host "`n=== Testing File Parser ===" -ForegroundColor Cyan

# Regex patterns (same as main script)
$reEmail  = '^(?=.{3,254}$)[A-Za-z0-9_.+\-\'']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
$reDomain = '^(\*\.)?[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

# Read and classify
$lines = Get-Content $TestFile
$emails = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
$domains = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)

foreach ($raw in $lines) {
    $line = ($raw -as [string]).Trim()

    # Skip empty lines and comments
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.StartsWith('#') -or $line.StartsWith(';')) { continue }

    # Classify
    if ($line -match $reEmail) {
        [void]$emails.Add($line)
        Write-Host "[EMAIL] $line" -ForegroundColor Green
        continue
    }

    if (($line -match $reDomain) -and -not ($line -like '*@*')) {
        if ($line.StartsWith('*.')) {
            $domain = $line.Substring(2)
            [void]$domains.Add($domain)
            Write-Host "[DOMAIN] $line -> $domain (wildcard converted)" -ForegroundColor Yellow
        } else {
            [void]$domains.Add($line)
            Write-Host "[DOMAIN] $line" -ForegroundColor Green
        }
        continue
    }

    Write-Host "[UNKNOWN] $line" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Emails found:  $($emails.Count)" -ForegroundColor White
Write-Host "Domains found: $($domains.Count)" -ForegroundColor White

Write-Host "`n=== Email List ===" -ForegroundColor Cyan
$emails.GetEnumerator() | Sort-Object | ForEach-Object { Write-Host "  - $_" }

Write-Host "`n=== Domain List ===" -ForegroundColor Cyan
$domains.GetEnumerator() | Sort-Object | ForEach-Object { Write-Host "  - $_" }

# Validation
$expectedEmails = 4
$expectedDomains = 4

if ($emails.Count -eq $expectedEmails -and $domains.Count -eq $expectedDomains) {
    Write-Host "`n[PASS] All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FAIL] Test failed!" -ForegroundColor Red
    Write-Host "Expected: $expectedEmails emails, $expectedDomains domains" -ForegroundColor Red
    Write-Host "Got:      $($emails.Count) emails, $($domains.Count) domains" -ForegroundColor Red
    exit 1
}
