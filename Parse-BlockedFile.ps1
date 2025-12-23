<#
.SYNOPSIS
    File Parsing Functions

.DESCRIPTION
    Parses the blocked.txt file and classifies entries into emails, domains, and keywords
#>

function Read-Lines {
    param([string]$Path)
    
    # Input validation: file exists, readable, proper format
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "TXT file not found: $Path (Only this file is read; please create it and try again.)"
    }
    
    $fileInfo = Get-Item -LiteralPath $Path
    if ($fileInfo.Length -eq 0) {
        throw "TXT file is empty: $Path"
    }
    
    # Check if file is readable
    try {
        $testRead = Get-Content -LiteralPath $Path -TotalCount 1 -ErrorAction Stop
    } catch {
        throw "TXT file is not readable: $Path - $($_.Exception.Message)"
    }
    
    # Memory efficient processing for large files
    $enc = [System.Text.UTF8Encoding]::new($false)
    
    # For large files, read in chunks to avoid memory issues
    if ($fileInfo.Length -gt 10MB) {
        Write-Info "Large file detected ($([math]::Round($fileInfo.Length/1MB, 2)) MB). Using memory-efficient processing."
        return Read-LargeFile -Path $Path -Encoding $enc
    } else {
        return [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path), $enc)
    }
}

function Read-LargeFile {
    param([string]$Path, [System.Text.Encoding]$Encoding)
    
    $lines = New-Object System.Collections.Generic.List[string]
    $bufferSize = 4096
    
    try {
        $reader = New-Object System.IO.StreamReader($Path, $Encoding, $false, $bufferSize)
        while (-not $reader.EndOfStream) {
            $line = $reader.ReadLine()
            if ($line) {
                $lines.Add($line)
            }
        }
    } finally {
        if ($reader) {
            $reader.Dispose()
        }
    }
    
    return $lines.ToArray()
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
    $duplicateCount = 0
    
    foreach ($raw in $Lines) {
        $i++
        $pct = if ($total -gt 0) { [math]::Floor(($i/$total)*100) } else { 100 }
        Write-Progress -Activity 'Reading TXT' -Status "Processing line ($i/$total)" -PercentComplete $pct

        $line = ($raw -as [string]).Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.Contains('---keywords---')) { $inKeywords = $true; continue }
        if ($line.StartsWith('#') -or $line.StartsWith(';')) { continue }

        if ($inKeywords) {
            if ($line) { 
                if ($keywords.Add($line)) {
                    # Successfully added (not duplicate)
                } else {
                    $duplicateCount++
                }
            }
            continue
        }

        if ($line -match $reEmail) { 
            if ($emails.Add($line)) {
                # Successfully added
            } else {
                $duplicateCount++
            }
            continue 
        }
        if (($line -match $reDomain) -and -not ($line -like '*@*')) {
            $domainToAdd = if ($line.StartsWith('*.')) { $line.Substring(2) } else { $line }
            if ($domains.Add($domainToAdd)) {
                # Successfully added
            } else {
                $duplicateCount++
            }
            continue
        }
    }

    if ($duplicateCount -gt 0) {
        Write-Info "Removed $duplicateCount duplicate entries during parsing."
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

