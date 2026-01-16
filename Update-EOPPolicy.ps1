<#
.SYNOPSIS
    EOP Policy Update Functions

.DESCRIPTION
    Updates Exchange Online Protection (EOP) spam filter policies
#>

function Ensure-PolicyExists {
    param([string]$Name)
    Write-Progress -Activity 'Policy Check' -Status "Checking policy: $Name" -PercentComplete 35
    $p = Get-HostedContentFilterPolicy -Identity $Name -ErrorAction SilentlyContinue
    if ($null -eq $p) { throw "Inbound anti-spam policy '$Name' not found. Please create it beforehand." }
}

function Update-BlockedLists {
    param([string]$PolicyName,[string[]]$Emails,[string[]]$Domains,[switch]$RemoveMissing,[switch]$DryRun)
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would update EOP policy '$PolicyName'"
        Write-Info "[DRY RUN] Would add $($Emails.Count) emails and $($Domains.Count) domains"
        return
    }
    
    Write-Progress -Activity 'Block Lists' -Status 'Reading current values...' -PercentComplete 65
    $policy = Get-HostedContentFilterPolicy -Identity $PolicyName

    # Convert current values to flat string list; API sometimes returns objects
    $currentEmails  = @($policy.BlockedSenders) | ForEach-Object { ($_ | Out-String).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $currentDomains = @($policy.BlockedSenderDomains) | ForEach-Object { ($_ | Out-String).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    # Add sets — safe comparison (only flat strings)
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
        Write-Progress -Activity 'Block Lists' -Status ("Adding emails ({0})" -f $toAddEmails.Count) -PercentComplete 75
        Write-ProgressLog "Adding $($toAddEmails.Count) emails to EOP Blocked Senders..."
        Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenders       @{ Add = $toAddEmails }
        Write-Info ("Added (emails): {0}" -f $toAddEmails.Count)
    }
    if ($toAddDomains.Count -gt 0) {
        Write-Progress -Activity 'Block Lists' -Status ("Adding domains ({0})" -f $toAddDomains.Count) -PercentComplete 80
        Write-ProgressLog "Adding $($toAddDomains.Count) domains to EOP Blocked Domains..."
        Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenderDomains @{ Add = $toAddDomains }
        Write-Info ("Added (domains): {0}" -f $toAddDomains.Count)
    }

    if ($RemoveMissing) {
        # Remove sets — safe string comparison
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
            Write-Progress -Activity 'Block Lists' -Status ("Removing emails ({0})" -f $toRemoveEmails.Count) -PercentComplete 85
            Write-ProgressLog "Removing $($toRemoveEmails.Count) emails from EOP Blocked Senders..."
            Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenders       @{ Remove = $toRemoveEmails }
            Write-Info ("Removed (emails): {0}" -f $toRemoveEmails.Count)
        }
        if ($toRemoveDomains.Count -gt 0) {
            Write-Progress -Activity 'Block Lists' -Status ("Removing domains ({0})" -f $toRemoveDomains.Count) -PercentComplete 90
            Write-ProgressLog "Removing $($toRemoveDomains.Count) domains from EOP Blocked Domains..."
            Set-HostedContentFilterPolicy -Identity $PolicyName -BlockedSenderDomains @{ Remove = $toRemoveDomains }
            Write-Info ("Removed (domains): {0}" -f $toRemoveDomains.Count)
        }
    }
}

