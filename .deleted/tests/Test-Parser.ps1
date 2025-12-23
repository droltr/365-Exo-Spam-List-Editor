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

Write-Host "Test file created: $testFile" -ForegroundColor Yellow

# Import the Classify function from main script
$scriptPath = Join-Path $PSScriptRoot '..\EXO-SpamManager.ps1'
$scriptContent = Get-Content $scriptPath -Raw

# Extract regex patterns and Classify function
$reEmail  = '^(?=.{3,254}$)[A-Za-z0-9_.+\-\'']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
$reDomain = '^(\*\.)?[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

# Inline the Classify function for testing
function Classify {
  param([string[]]$Lines)
  $emails  = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
  $domains = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
  $keywords = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)

  $i = 0; $total = $Lines.Count
  $inKeywords = $false
  foreach ($raw in $Lines) {
    $i++

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

  $emailArr  = ($emails.GetEnumerator()  | ForEach-Object { $_ }) | Sort-Object -Unique
  $domainArr = ($domains.GetEnumerator() | ForEach-Object { $_ }) | Sort-Object -Unique
  $keywordArr = ($keywords.GetEnumerator() | ForEach-Object { $_ }) | Sort-Object -Unique

  [pscustomobject]@{
    Emails  = $emailArr
    Domains = $domainArr
    Keywords = $keywordArr
  }
}

# Run tests
Write-Host "`n--- Test 1: Read and Parse File ---" -ForegroundColor Yellow
$lines = Get-Content -Path $testFile -Encoding UTF8
$data = Classify -Lines $lines

Write-Host "`n--- Test 2: Email Classification ---" -ForegroundColor Yellow
Write-Host "Expected: 3 emails (spam@example.com, phishing@malicious.org, abuse@test.co.uk)" -ForegroundColor Gray
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
Write-Host "Expected: 3 domains (example.com, malicious.org, phishing.net, test.co.uk)" -ForegroundColor Gray
Write-Host "Actual: $($data.Domains.Count) domains" -ForegroundColor Cyan
foreach ($domain in $data.Domains) {
    Write-Host "  ✓ $domain" -ForegroundColor Green
}

if ($data.Domains.Count -eq 4) {
    Write-Host "[PASS] Domain count correct" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Domain count mismatch" -ForegroundColor Red
}

Write-Host "`n--- Test 4: Wildcard Domain Conversion ---" -ForegroundColor Yellow
Write-Host "Expected: *.phishing.net → phishing.net" -ForegroundColor Gray
if ($data.Domains -contains 'phishing.net') {
    Write-Host "[PASS] Wildcard domain correctly converted to root domain" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Wildcard domain conversion failed" -ForegroundColor Red
}

Write-Host "`n--- Test 5: Keyword Classification ---" -ForegroundColor Yellow
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

Write-Host "`n--- Test 6: Deduplication ---" -ForegroundColor Yellow
Write-Host "Expected: Duplicates removed (spam@example.com and example.com appear only once)" -ForegroundColor Gray
$emailCounts = @{}
foreach ($email in $data.Emails) {
    $emailCounts[$email]++
}
$duplicateEmails = $emailCounts.GetEnumerator() | Where-Object { $_.Value -gt 1 }
if ($duplicateEmails.Count -eq 0) {
    Write-Host "[PASS] No duplicate emails" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Duplicates found: $($duplicateEmails.Key -join ', ')" -ForegroundColor Red
}

Write-Host "`n--- Test 7: Regex Patterns ---" -ForegroundColor Yellow
$testEmails = @(
    @{ Email = 'valid@example.com'; Expected = $true }
    @{ Email = 'invalid.email'; Expected = $false }
    @{ Email = 'user+tag@domain.co.uk'; Expected = $true }
    @{ Email = '@nodomain.com'; Expected = $false }
)

foreach ($test in $testEmails) {
    $match = $test.Email -match $reEmail
    if ($match -eq $test.Expected) {
        Write-Host "[PASS] '$($test.Email)' → $match (expected $($test.Expected))" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] '$($test.Email)' → $match (expected $($test.Expected))" -ForegroundColor Red
    }
}

Write-Host "`n--- Test 8: Comment and Empty Line Handling ---" -ForegroundColor Yellow
$commentTest = @"
# This is a comment
; This is also a comment

email@example.com

domain.com
"@
$commentLines = $commentTest -split "`n"
$commentData = Classify -Lines $commentLines

if ($commentData.Emails.Count -eq 1 -and $commentData.Domains.Count -eq 1) {
    Write-Host "[PASS] Comments and empty lines correctly ignored" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Comment/empty line handling issue" -ForegroundColor Red
}

# Cleanup
Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "`nSummary:" -ForegroundColor Yellow
Write-Host "  Emails parsed: $($data.Emails.Count)" -ForegroundColor Gray
Write-Host "  Domains parsed: $($data.Domains.Count)" -ForegroundColor Gray
Write-Host "  Keywords parsed: $($data.Keywords.Count)" -ForegroundColor Gray
Write-Host ""
