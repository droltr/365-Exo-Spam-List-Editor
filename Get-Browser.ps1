<#
.SYNOPSIS
    Browser Detection Functions

.DESCRIPTION
    Detects the user's default web browser for authentication
#>

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