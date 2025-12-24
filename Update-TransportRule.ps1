<#
.SYNOPSIS
    Transport Rule Update Functions

.DESCRIPTION
    Manages Exchange Online Transport Rules for spam filtering
#>

function Ensure-RuleForAllAcceptedDomains {
    param([string]$RuleName,[string]$PolicyName)
    Write-Progress -Activity 'Scope Setting' -Status 'Getting accepted domains...' -PercentComplete 50

    # Get all accepted domains; exclude onmicrosoft
    $accepted = (Get-AcceptedDomain | Where-Object { -not $_.DomainName.EndsWith('.onmicrosoft.com') }).DomainName
    if (-not $accepted -or $accepted.Count -eq 0) { $accepted = (Get-AcceptedDomain).DomainName }
    $domains = $accepted | Sort-Object -Unique

    # Search for rule by exact name first
    $r = Get-HostedContentFilterRule -Identity $RuleName -ErrorAction SilentlyContinue

    # If exact name not found, check if another rule is associated with the same policy
    if ($null -eq $r) {
        $existingForPolicy = Get-HostedContentFilterRule -ErrorAction SilentlyContinue | Where-Object { $_.HostedContentFilterPolicy -eq $PolicyName } | Select-Object -First 1
        if ($existingForPolicy) {
            Write-Info "Policy '$PolicyName' is already associated with rule '$($existingForPolicy.Name)'; updating existing rule."
            $r = $existingForPolicy
        }
    }

    if ($null -eq $r) {
        # Create new rule if no related rule exists
        Write-Info "Creating inbound rule: $RuleName"
        New-HostedContentFilterRule -Name $RuleName -HostedContentFilterPolicy $PolicyName -RecipientDomainIs $domains -Enabled:$true | Out-Null
        return
    }

    # Update existing rule as needed
    $changed = $false
    $identityToUse = $r.Name
    if ($r.HostedContentFilterPolicy -ne $PolicyName) {
        Set-HostedContentFilterRule -Identity $identityToUse -HostedContentFilterPolicy $PolicyName | Out-Null
        $changed = $true
    }
    $current = @($r.RecipientDomainIs)
    if (@(Compare-Object -ReferenceObject $current -DifferenceObject $domains).Count -gt 0) {
        Set-HostedContentFilterRule -Identity $identityToUse -RecipientDomainIs $domains | Out-Null
        $changed = $true
    }
    # 'Enabled' property may not exist on deserialized/older objects; access safely
    if ($null -ne $r.PSObject.Properties['Enabled']) {
        if (-not $r.Enabled) {
            Set-HostedContentFilterRule -Identity $identityToUse -Enabled:$true | Out-Null
            $changed = $true
        }
    } else {
        Write-Info "Rule '$identityToUse' object has no 'Enabled' property; skipping Enabled setting."
    }
    if ($changed) { Write-Info 'Inbound rule updated.' }
}

function Update-TransportRule {
    param([string]$RuleName, [string[]]$Emails, [string[]]$Domains, [string[]]$Keywords, [switch]$RemoveMissing, [switch]$DryRun)

    if ($DryRun) {
        Write-Info "[DRY RUN] Would update Transport Rule '$RuleName'"
        Write-Info "[DRY RUN] Would add $($Emails.Count) emails, $($Domains.Count) domains, $($Keywords.Count) keywords"
        return
    }

    Write-Progress -Activity 'Transport Rule' -Status 'Checking Transport Rule...' -PercentComplete 60
    $tr = Get-TransportRule -Identity $RuleName -ErrorAction SilentlyContinue

    if ($null -eq $tr) {
        Write-Info "Creating Transport Rule: $RuleName"
        # Create new rule with initial values (if any)
        $params = @{
            Name = $RuleName
            Enabled = $true
            RejectMessageReasonText = "Message blocked by spam filter policy"
            StopRuleProcessing = $true
        }

        if ($Emails.Count -gt 0) { $params['From'] = $Emails }
        if ($Domains.Count -gt 0) { $params['SenderDomainIs'] = $Domains }
        if ($Keywords.Count -gt 0) { $params['SubjectOrBodyContainsWords'] = $Keywords }

        # Only create if we have at least one condition
        if ($Emails.Count -gt 0 -or $Domains.Count -gt 0 -or $Keywords.Count -gt 0) {
            New-TransportRule @params | Out-Null
            Write-Info "Transport Rule created."
        } else {
            Write-Info "No entries for Transport Rule, skipping creation."
        }
        return
    }

    # Update existing rule
    Write-Info "Updating Transport Rule: $RuleName"

    # For Transport Rules, we generally replace the lists if we are in sync mode or just adding
    # But since Transport Rules don't have simple "Add/Remove" methods like policies,
    # we usually set the full list.

    # If RemoveMissing is false (incremental), we need to merge with existing
    $newEmails = @($Emails)
    $newDomains = @($Domains)
    $newKeywords = @($Keywords)

    if (-not $RemoveMissing) {
        if ($tr.From) { $newEmails += $tr.From }
        if ($tr.SenderDomainIs) { $newDomains += $tr.SenderDomainIs }
        if ($tr.SubjectOrBodyContainsWords) { $newKeywords += $tr.SubjectOrBodyContainsWords }

        $newEmails = $newEmails | Sort-Object -Unique
        $newDomains = $newDomains | Sort-Object -Unique
        $newKeywords = $newKeywords | Sort-Object -Unique
    }

    $params = @{ Identity = $tr.Identity }
    $updated = $false

    # Update From (Emails)
    if ($newEmails.Count -gt 0) {
        $params['From'] = $newEmails
        $updated = $true
    } elseif ($RemoveMissing -and $tr.From) {
        # If syncing and list is empty, we might need to clear it, but Set-TransportRule doesn't like empty lists for some params
        # Strategy: If list is empty, we don't set the parameter, effectively leaving it or we might need to remove the condition
        # For simplicity in this script, we update if we have values.
        $params['From'] = $null # This might fail depending on PS version, usually better to not pass it
    }

    # Update SenderDomainIs
    if ($newDomains.Count -gt 0) {
        $params['SenderDomainIs'] = $newDomains
        $updated = $true
    }

    # Update Keywords
    if ($newKeywords.Count -gt 0) {
        $params['SubjectOrBodyContainsWords'] = $newKeywords
        $updated = $true
    }

    if ($updated) {
        Set-TransportRule @params | Out-Null
        Write-Info "Transport Rule updated."
    }
}



function Check-ExistingRules {
    param([string]$RuleName)
    
    Write-Progress -Activity 'Rule Check' -Status "Checking existing rule: $RuleName" -PercentComplete 10
    
    # Check if rule exists
    $existingRule = Get-TransportRule -Identity $RuleName -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        Write-Info "Found existing Transport Rule: '$RuleName'"
        return $true
    } else {
        Write-Info "Transport Rule '$RuleName' does not exist"
        return $false
    }
}

function Create-OrUpdateRule {
    param([string]$RuleName, [string[]]$Emails, [string[]]$Domains, [string[]]$Keywords)
    
    $ruleExists = Check-ExistingRules -RuleName $RuleName
    
    if (-not $ruleExists) {
        Write-Info "Creating new Transport Rule: '$RuleName'"
        Write-ProgressLog "Creating new Transport Rule '$RuleName'..."
        # Create new rule with initial values
        $params = @{
            Name = $RuleName
            Enabled = $true
            RejectMessageReasonText = "Message blocked by spam filter policy"
            StopRuleProcessing = $true
        }

        if ($Emails.Count -gt 0) { $params['From'] = $Emails }
        if ($Domains.Count -gt 0) { $params['SenderDomainIs'] = $Domains }
        if ($Keywords.Count -gt 0) { $params['SubjectOrBodyContainsWords'] = $Keywords }

        # Only create if we have at least one condition
        if ($Emails.Count -gt 0 -or $Domains.Count -gt 0 -or $Keywords.Count -gt 0) {
            New-TransportRule @params | Out-Null
            Write-Info "Transport Rule created successfully."
        } else {
            Write-Info "No entries for Transport Rule, skipping creation."
        }
    } else {
        Write-Info "Updating existing Transport Rule: '$RuleName'"
        # Update existing rule - add new entries
        Update-ExistingRule -RuleName $RuleName -Emails $Emails -Domains $Domains -Keywords $Keywords
    }
}

function Update-ExistingRule {
    param([string]$RuleName, [string[]]$Emails, [string[]]$Domains, [string[]]$Keywords)
    
    $tr = Get-TransportRule -Identity $RuleName
    
    # Get current values
    $currentEmails = @($tr.From)
    $currentDomains = @($tr.SenderDomainIs)
    $currentKeywords = @($tr.SubjectOrBodyContainsWords)
    
    # Merge with new values (incremental add)
    $newEmails = @($currentEmails) + @($Emails) | Sort-Object -Unique
    $newDomains = @($currentDomains) + @($Domains) | Sort-Object -Unique
    $newKeywords = @($currentKeywords) + @($Keywords) | Sort-Object -Unique
    
    $params = @{ Identity = $tr.Identity }
    $updated = $false
    
    # Update From (Emails)
    if ($newEmails.Count -gt 0) {
        $params['From'] = $newEmails
        $updated = $true
    }
    
    # Update SenderDomainIs
    if ($newDomains.Count -gt 0) {
        $params['SenderDomainIs'] = $newDomains
        $updated = $true
    }
    
    # Update Keywords
    if ($newKeywords.Count -gt 0) {
        $params['SubjectOrBodyContainsWords'] = $newKeywords
        $updated = $true
    }
    
    if ($updated) {
        Write-ProgressLog "Applying updates to Transport Rule '$RuleName'..."
        Set-TransportRule @params | Out-Null
        Write-Info "Transport Rule updated successfully."
    }
}