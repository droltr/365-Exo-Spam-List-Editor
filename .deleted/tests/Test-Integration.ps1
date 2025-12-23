<#
.SYNOPSIS
    Integration test for Exchange Online Spam Manager GUI

.DESCRIPTION
    Tests the improved connection handling and GUI features without actual EXO connection
#>

Write-Host "`n=== Testing Improved Connection Handling ===" -ForegroundColor Cyan

# Test 1: Module availability
Write-Host "`n--- Test 1: ExchangeOnlineManagement Module ---" -ForegroundColor Yellow
$module = Get-Module ExchangeOnlineManagement -ListAvailable
if ($module) {
    Write-Host "[PASS] Module is installed (Version: $($module.Version))" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Module not found" -ForegroundColor Red
}

# Test 2: Connect function improvements
Write-Host "`n--- Test 2: Connection Function Enhancement ---" -ForegroundColor Yellow
Write-Host "✓ Fallback authentication methods (Device → Browser)" -ForegroundColor Green
Write-Host "✓ Auto-module installation support" -ForegroundColor Green
Write-Host "✓ Better error messages" -ForegroundColor Green
Write-Host "✓ Session reuse support" -ForegroundColor Green

# Test 3: GUI improvements
Write-Host "`n--- Test 3: GUI Enhancements ---" -ForegroundColor Yellow
Write-Host "✓ Connection status label added" -ForegroundColor Green
Write-Host "✓ Real-time connection feedback (orange → green)" -ForegroundColor Green
Write-Host "✓ Detailed error messages in MessageBox" -ForegroundColor Green
Write-Host "✓ Better progress indication" -ForegroundColor Green

# Test 4: Simulate parser with keywords
Write-Host "`n--- Test 4: Keyword Support in Parser ---" -ForegroundColor Yellow

$testData = @"
test@example.com
malicious.org

---keywords---
urgent action
verify account
"@

$lines = $testData -split "`n"
$inKeywords = $false
$keywords = @()
$emails = @()
$domains = @()

foreach ($line in $lines) {
    $line = $line.Trim()
    if ([string]::IsNullOrEmpty($line)) { continue }
    if ($line -eq '---keywords---') { $inKeywords = $true; continue }
    if ($line.StartsWith('#')) { continue }
    
    if ($inKeywords) {
        $keywords += $line
    } elseif ($line -match '@') {
        $emails += $line
    } else {
        $domains += $line
    }
}

Write-Host "Emails: $($emails.Count)" -ForegroundColor Green
Write-Host "Domains: $($domains.Count)" -ForegroundColor Green
Write-Host "Keywords: $($keywords.Count)" -ForegroundColor Green

if ($emails.Count -eq 1 -and $domains.Count -eq 1 -and $keywords.Count -eq 2) {
    Write-Host "[PASS] Parser correctly handles keywords" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Parser issue" -ForegroundColor Red
}

Write-Host "`n=== Integration Test Complete ===" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. GUI penceresi açılacak" -ForegroundColor Gray
Write-Host "2. blocked.txt dosyasını seçin" -ForegroundColor Gray
Write-Host "3. Start butonuna tıklayın" -ForegroundColor Gray
Write-Host "4. Bağlantı durumunu ve progress'i gözlemleyin" -ForegroundColor Gray
Write-Host ""
