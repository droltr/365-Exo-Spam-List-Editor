<#
.SYNOPSIS
    Test script for file parsing and classification logic

.DESCRIPTION
    Tests the Classify function and email/domain regex patterns
    to verify that blocked entries are correctly categorized.

.EXAMPLE
    .\tests\Test-Parser.ps1

#>

Write-Host "`n=== Testing Parser and Classification ===" -ForegroundColor Cyan

# Import the parser module
. "$PSScriptRoot\..\Common-Utils.ps1"
. "$PSScriptRoot\..\Parse-BlockedFile.ps1"

# Test data
$testData = @"
# This is a comment
; This is also a comment

# Email addresses
spam@example.com
phishing@malicious.org
abuse@test.co.uk

# Domains
example.com
malicious.org
*.phishing.net
test.co.uk

# Duplicates (should be deduplicated)
spam@example.com
example.com

# Empty lines should be ignored


# Keywords section
---keywords---
urgent action required
verify account
confirm password
update billing
"@

# Create test file
$testFile = Join-Path $PSScriptRoot 'test-blocked.txt'
$testData | Out-File -FilePath $testFile -Encoding UTF8 -Force

# Test the parser
$lines = Read-Lines -Path $testFile
$data = Classify -Lines $lines

Write-Host "`n--- Test 1: Basic Parsing ---" -ForegroundColor Yellow
Write-Host "Total lines processed: $($lines.Count)" -ForegroundColor Gray
Write-Host "Classification results:" -ForegroundColor Cyan
Write-Host "  Emails: $($data.Emails.Count)" -ForegroundColor Green
Write-Host "  Domains: $($data.Domains.Count)" -ForegroundColor Green
Write-Host "  Keywords: $($data.Keywords.Count)" -ForegroundColor Green

Write-Host "`n--- Test 2: Email Classification ---" -ForegroundColor Yellow
Write-Host "Expected: 3 emails" -ForegroundColor Gray
Write-Host "Actual: $($data.Emails.Count) emails" -ForegroundColor Cyan
foreach ($email in $data.Emails) {
    Write-Host "  ✓ $email" -ForegroundColor Green
}

if ($data.Emails.Count -eq 3) {
    Write-Host "[PASS] Email count correct" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Email count mismatch" -ForegroundColor Red
}

Write-Host "`n--- Test 3: Domain Classification ---" -ForegroundColor Yellow
Write-Host "Expected: 4 domains" -ForegroundColor Gray
Write-Host "Actual: $($data.Domains.Count) domains" -ForegroundColor Cyan
foreach ($domain in $data.Domains) {
    Write-Host "  ✓ $domain" -ForegroundColor Green
}

if ($data.Domains.Count -eq 4) {
    Write-Host "[PASS] Domain count correct" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Domain count mismatch" -ForegroundColor Red
}

Write-Host "`n--- Test 4: Keyword Classification ---" -ForegroundColor Yellow
Write-Host "Expected: 4 keywords" -ForegroundColor Gray
Write-Host "Actual: $($data.Keywords.Count) keywords" -ForegroundColor Cyan
foreach ($keyword in $data.Keywords) {
    Write-Host "  ✓ $keyword" -ForegroundColor Green
}

if ($data.Keywords.Count -eq 4) {
    Write-Host "[PASS] Keyword count correct" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Keyword count mismatch" -ForegroundColor Red
}

# Cleanup
Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "`nSummary:" -ForegroundColor Yellow
Write-Host "  Emails parsed: $($data.Emails.Count)" -ForegroundColor Gray
Write-Host "  Domains parsed: $($data.Domains.Count)" -ForegroundColor Gray
Write-Host "  Keywords parsed: $($data.Keywords.Count)" -ForegroundColor Gray
Write-Host ""
Write-Host ""
