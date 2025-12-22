<#
.SYNOPSIS
    Test script for default browser detection

.DESCRIPTION
    Tests the Get-DefaultBrowser function to verify it correctly detects the user's default browser
#>

Write-Host "`n=== Testing Browser Detection ===" -ForegroundColor Cyan

# Import the function from main script
$scriptContent = Get-Content "$PSScriptRoot\..\EXO-SpamManager.ps1" -Raw
$functionMatch = $scriptContent -match '(?s)function Get-DefaultBrowser \{.*?\n\}'
if ($functionMatch) {
    # Extract and execute the function
    $null = Invoke-Expression ($Matches[0])
    Write-Host "[OK] Function loaded successfully" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Could not extract function" -ForegroundColor Red
    exit 1
}

# Test 1: Check registry for default browser
Write-Host "`n--- Test 1: Registry Detection ---" -ForegroundColor Yellow
try {
    $regKey = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' -ErrorAction Stop
    Write-Host "Default Browser ProgId: $($regKey.ProgId)" -ForegroundColor Cyan
} catch {
    Write-Host "Could not read registry (not an error, may not be set)" -ForegroundColor Gray
}

# Test 2: Run the function
Write-Host "`n--- Test 2: Function Execution ---" -ForegroundColor Yellow
$VerbosePreference = 'Continue'
$browser = Get-DefaultBrowser
$VerbosePreference = 'SilentlyContinue'

# Test 3: Verify results
Write-Host "`n--- Test 3: Results ---" -ForegroundColor Yellow
if ($browser) {
    Write-Host "[SUCCESS] Browser detected!" -ForegroundColor Green
    Write-Host "  Name: $($browser.Name)" -ForegroundColor White
    Write-Host "  Path: $($browser.Path)" -ForegroundColor White
    Write-Host "  Args: $($browser.Args)" -ForegroundColor White

    if (Test-Path $browser.Path) {
        Write-Host "  [OK] Browser executable exists" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Browser executable not found!" -ForegroundColor Red
    }
} else {
    Write-Host "[INFO] No specific browser detected, will use system default" -ForegroundColor Yellow
}

# Test 4: Common browsers check
Write-Host "`n--- Test 4: Installed Browsers ---" -ForegroundColor Yellow
$commonBrowsers = @(
    @{ Name = 'Microsoft Edge'; Path = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe' }
    @{ Name = 'Google Chrome'; Path = 'C:\Program Files\Google\Chrome\Application\chrome.exe' }
    @{ Name = 'Mozilla Firefox'; Path = 'C:\Program Files\Mozilla Firefox\firefox.exe' }
    @{ Name = 'Brave'; Path = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe" }
)

foreach ($br in $commonBrowsers) {
    if (Test-Path $br.Path) {
        Write-Host "  [FOUND] $($br.Name)" -ForegroundColor Green
    } else {
        Write-Host "  [NOT INSTALLED] $($br.Name)" -ForegroundColor Gray
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
