# Usage Guide

Complete guide for using the Exchange Online Spam Manager.

## Table of Contents

- [GUI Mode](#gui-mode)
- [CLI Mode](#cli-mode)
- [File Format](#file-format)
- [Common Scenarios](#common-scenarios)
- [Best Practices](#best-practices)
- [Advanced Usage](#advanced-usage)

## GUI Mode

The GUI provides the easiest way to manage spam filters.

### Starting the GUI

```powershell
.\Start-SpamManager.ps1
```

### GUI Walkthrough

1. **File Selection**
   - Click **Browse** to select your blocked entries file
   - Or type the path directly in the text box
   - Default: `.\blocked.txt`

2. **Options**
   - **Sync Mode**: Check this to remove entries not in your file
   - ⚠️ Warning: Unchecked items in your policy will be removed!

3. **Start Processing**
   - Click **Start** button
   - Monitor progress in the output window
   - Wait for completion message

4. **Review Results**
   - Check the summary in the output window
   - View count of added/removed entries
   - Click **Close** when done

### GUI Features

- **Real-time Progress**: Live progress bar and status updates
- **Detailed Logging**: All operations logged in output window
- **Error Handling**: Clear error messages with troubleshooting hints
- **File Validation**: Checks if file exists before processing

## CLI Mode

For automation, scripting, or advanced users.

### Basic Usage

Add entries from a file (incremental):
```powershell
.\EXO-SpamManager.ps1 -BlockedTxtPath "C:\spam\blocked.txt"
```

### Sync Mode

Remove entries not in the file:
```powershell
.\EXO-SpamManager.ps1 -BlockedTxtPath "C:\spam\blocked.txt" -RemoveMissing
```

### Custom Policy Names

Use different policy and rule names:
```powershell
.\EXO-SpamManager.ps1 `
    -BlockedTxtPath "C:\spam\blocked.txt" `
    -PolicyName "CustomSpamPolicy" `
    -RuleName "Custom Inbound Rule"
```

### Complete Parameter List

```powershell
.\EXO-SpamManager.ps1 `
    -BlockedTxtPath "C:\spam\blocked.txt" `  # Path to blocked entries file
    -PolicyName "Spam" `                      # Name of spam policy (default: "Spam")
    -RuleName "Spam (Inbound Rule)" `        # Name of inbound rule
    -RemoveMissing                            # Sync mode switch
```

## File Format

### Structure

Your `blocked.txt` file can contain:

```
# Comments start with # or ;
; This is also a comment

# Email addresses (one per line)
spam@example.com
phishing@malicious.org

# Domains (with or without wildcard)
spammer.com
malicious.net
*.phishing-domain.org

# IP addresses (for future use)
192.168.1.100
203.0.113.50

# Keywords section (for future use)
---keywords---
suspicious phrase
crypto scam
```

### Supported Entry Types

| Type | Format | Destination | Example |
|------|--------|-------------|---------|
| Email | `user@domain.com` | BlockedSenders | `spam@bad.com` |
| Domain | `domain.com` | BlockedSenderDomains | `malicious.org` |
| Wildcard | `*.domain.com` | BlockedSenderDomains (root) | `*.spam.net` → `spam.net` |
| IP Address | `xxx.xxx.xxx.xxx` | *(Not yet implemented)* | `192.168.1.1` |
| Keywords | Text after `---keywords---` | *(Not yet implemented)* | `scam phrase` |

### Wildcard Handling

- `*.example.com` → Converted to `example.com`
- This blocks all subdomains of example.com
- Exchange Online handles wildcard blocking at the root domain level

### Comments

```
# Full line comment
; Alternative comment style

spam@example.com  # Inline comments are NOT supported (will cause errors)
```

## Common Scenarios

### Scenario 1: First Time Setup

```powershell
# 1. Create your blocked list
Copy-Item blocked.example.txt blocked.txt
notepad blocked.txt

# 2. Add entries
# Add emails and domains, one per line

# 3. Run the tool
.\Start-SpamManager.ps1

# 4. Select file and click Start
```

### Scenario 2: Adding New Entries

```powershell
# 1. Edit your blocked.txt
notepad blocked.txt

# 2. Add new entries at the end

# 3. Run tool (incremental mode)
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt"

# Existing entries remain, new ones are added
```

### Scenario 3: Complete Sync

```powershell
# 1. Update blocked.txt with complete list
notepad blocked.txt

# 2. Remove unwanted entries from file

# 3. Run with sync mode
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt" -RemoveMissing

# Policy will match file exactly
```

### Scenario 4: Multiple Policies

```powershell
# Manage different policies for different purposes

# Policy 1: General spam
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\general-spam.txt" -PolicyName "GeneralSpam"

# Policy 2: Phishing
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\phishing.txt" -PolicyName "Phishing"

# Policy 3: Executive protection
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\executive-spam.txt" -PolicyName "ExecutiveSpam"
```

### Scenario 5: Automated Daily Updates

```powershell
# Create script: C:\scripts\update-spam-daily.ps1

param()
Set-Location C:\exchange-spam-manager

# Pull latest blocked list from source
# (e.g., shared drive, database, API, etc.)
Copy-Item "\\server\share\blocked.txt" -Destination ".\blocked.txt" -Force

# Update spam filter
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt" -RemoveMissing

# Send email notification
$summary = Get-Content .\last-run.log -Tail 10
Send-MailMessage -To "admin@company.com" -Subject "Spam Filter Updated" -Body $summary
```

Then schedule it:
```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\scripts\update-spam-daily.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "Update Spam Filter" -Action $action -Trigger $trigger
```

## Best Practices

### 1. File Management

✅ **DO:**
- Keep blocked.txt under version control (Git)
- Use meaningful comments to document why entries were added
- Regularly review and clean up old entries
- Back up your file before sync operations

❌ **DON'T:**
- Add inline comments (not supported)
- Mix tabs and spaces (use consistent formatting)
- Include sensitive information in comments if file is shared

### 2. Testing

✅ **DO:**
- Test with a small file first
- Use incremental mode initially
- Verify results in Exchange Admin Center after running
- Test with non-production policy first

❌ **DON'T:**
- Run sync mode without backup
- Make changes during business hours initially
- Skip verification of results

### 3. Maintenance

✅ **DO:**
- Review blocked lists monthly
- Remove entries that are no longer relevant
- Document major changes in file comments
- Monitor false positives

❌ **DON'T:**
- Leave the list growing indefinitely
- Forget to communicate with users about blocking
- Ignore user reports of legitimate blocked emails

### 4. Security

✅ **DO:**
- Use least-privilege accounts when possible
- Enable MFA for Exchange admin accounts
- Log all changes
- Review permissions regularly

❌ **DON'T:**
- Share admin credentials
- Run from untrusted sources
- Disable security features

## Advanced Usage

### Filtering and Validation

Pre-validate your file before running:

```powershell
# Check for duplicates
Get-Content blocked.txt | Group-Object | Where-Object { $_.Count -gt 1 }

# Count entries by type
$content = Get-Content blocked.txt
$emails = $content | Where-Object { $_ -match '@' }
$domains = $content | Where-Object { $_ -match '\.' -and $_ -notmatch '@' }

Write-Host "Emails: $($emails.Count)"
Write-Host "Domains: $($domains.Count)"
```

### Exporting Current Policy

Export current blocked lists:

```powershell
Connect-ExchangeOnline

$policy = Get-HostedContentFilterPolicy -Identity "Spam"

# Export to file
$policy.BlockedSenders | Out-File "current-blocked-senders.txt"
$policy.BlockedSenderDomains | Out-File "current-blocked-domains.txt"

Disconnect-ExchangeOnline -Confirm:$false
```

### Merging Multiple Sources

Combine multiple blocked lists:

```powershell
# Merge files
Get-Content list1.txt, list2.txt, list3.txt |
    Sort-Object -Unique |
    Out-File merged-blocked.txt

# Run update
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\merged-blocked.txt"
```

### Dry Run (Simulation)

See what would be changed without making changes:

```powershell
# Not built-in, but you can manually check:
Connect-ExchangeOnline

$policy = Get-HostedContentFilterPolicy -Identity "Spam"
$currentEmails = $policy.BlockedSenders
$currentDomains = $policy.BlockedSenderDomains

# Compare with your file
$fileContent = Get-Content blocked.txt | Where-Object { $_ -match '@' }
$toAdd = $fileContent | Where-Object { $_ -notin $currentEmails }
$toRemove = $currentEmails | Where-Object { $_ -notin $fileContent }

Write-Host "Would add: $($toAdd.Count)"
Write-Host "Would remove: $($toRemove.Count)"

Disconnect-ExchangeOnline -Confirm:$false
```

### Logging and Auditing

Redirect output to log file:

```powershell
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt" |
    Tee-Object -FilePath "spam-update-$(Get-Date -Format 'yyyy-MM-dd').log"
```

## Integration Examples

### With Email Alerts

```powershell
try {
    .\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt"
    Send-MailMessage -To "team@company.com" -Subject "Spam Filter Updated" -Body "Success"
} catch {
    Send-MailMessage -To "admin@company.com" -Subject "Spam Filter FAILED" -Body $_.Exception.Message
}
```

### With SharePoint List

```powershell
# Export SharePoint list to CSV
# Import and convert to blocked.txt format
$spamList = Import-Csv "spam-from-sharepoint.csv"
$spamList.Email | Out-File blocked.txt

.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt"
```

### With Threat Intelligence Feed

```powershell
# Download threat feed
Invoke-WebRequest -Uri "https://threatfeed.example.com/spam-domains.txt" -OutFile "threat-feed.txt"

# Merge with local list
Get-Content blocked.txt, threat-feed.txt | Sort-Object -Unique | Out-File merged.txt

# Update
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\merged.txt" -RemoveMissing
```

## Troubleshooting Tips

### Changes Not Applying

1. Wait 15-30 minutes for propagation
2. Check policy is assigned to correct rule
3. Verify rule is enabled and scoped correctly
4. Check Exchange Online message trace

### Performance Issues

1. Split large files into batches
2. Run during off-peak hours
3. Use incremental mode instead of sync
4. Limit file to 5000-10000 entries

### Authentication Loops

1. Clear browser cache
2. Use InPrivate/Incognito mode
3. Update ExchangeOnlineManagement module
4. Check conditional access policies

## Getting Help

- Check [FAQ.md](FAQ.md) for common questions
- Review [INSTALL.md](INSTALL.md) for setup issues
- Search GitHub issues
- Create new issue with detailed error logs

---

**Happy spam filtering!** 🛡️
