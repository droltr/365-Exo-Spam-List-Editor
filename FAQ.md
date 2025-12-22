# Frequently Asked Questions (FAQ)

## General Questions

### What does this tool do?

This tool automates the management of Exchange Online spam filtering by importing blocked email addresses and domains from a text file into your spam policies.

### Is this an official Microsoft tool?

No, this is a community-developed tool that uses the official Microsoft Exchange Online Management PowerShell module.

### Does it work with on-premises Exchange?

No, this tool is designed specifically for Exchange Online (Microsoft 365). It does not support on-premises Exchange Server.

### Is it free?

Yes, this tool is completely free and open-source under the MIT License.

## Installation & Setup

### What are the prerequisites?

- Windows operating system
- PowerShell 5.1 or later
- Exchange Online administrator permissions
- ExchangeOnlineManagement PowerShell module

### Do I need administrator rights on my computer?

You need admin rights to install the PowerShell module initially, but you can use `-Scope CurrentUser` to install without admin rights.

### Can I run this on macOS or Linux?

Not currently. The GUI uses Windows Forms which is Windows-only. However, the core script might work with PowerShell 7 on macOS/Linux (untested).

### How do I know if I have the right permissions?

You need one of these Exchange Online roles:
- Global Administrator
- Exchange Administrator
- Security Administrator

Check at: [Microsoft 365 Admin Center](https://admin.microsoft.com) → Users → Active Users → Select your account → Roles

## Usage Questions

### What's the difference between incremental and sync mode?

- **Incremental (default)**: Adds new entries from your file without removing existing entries in the policy
- **Sync mode (`-RemoveMissing`)**: Makes the policy match your file exactly by removing entries not in the file

### Can I undo changes?

Not automatically. Before running sync mode:
1. Export current policy settings
2. Keep a backup of your blocked.txt
3. Test with a small file first

To manually undo:
```powershell
Connect-ExchangeOnline
Set-HostedContentFilterPolicy -Identity "Spam" -BlockedSenders @{Remove = "email@example.com"}
```

### How long do changes take to apply?

Changes are immediate in the policy, but email filtering may take 15-30 minutes to propagate across Exchange Online servers.

### Can I manage multiple policies?

Yes! Use the `-PolicyName` parameter:

```powershell
.\EXO-SpamManager.ps1 -BlockedTxtPath "policy1.txt" -PolicyName "Policy1"
.\EXO-SpamManager.ps1 -BlockedTxtPath "policy2.txt" -PolicyName "Policy2"
```

### What happens to emails already in the inbox?

Nothing. The policy only affects new incoming emails. Existing emails are not retroactively blocked or removed.

### Can I block by IP address?

Not yet. IP address blocking is planned for a future release. Currently, only email addresses and domains are supported.

### Can I use wildcards?

Wildcards in the format `*.domain.com` are supported but are automatically converted to the root domain `domain.com` because Exchange Online handles wildcard blocking at the domain level.

### How many entries can I add?

Exchange Online has limits:
- **BlockedSenders**: 1,024 entries
- **BlockedSenderDomains**: 1,024 entries

The tool will fail if you exceed these limits.

## File Format Questions

### What file format is supported?

Plain text files (.txt) with UTF-8 encoding. One entry per line.

### Can I use CSV files?

Not directly, but you can convert:

```powershell
Import-Csv spam.csv | Select-Object -ExpandProperty Email | Out-File blocked.txt
```

### Can I add comments?

Yes! Lines starting with `#` or `;` are treated as comments:

```
# This is a comment
spam@example.com
; This is also a comment
```

### Are blank lines allowed?

Yes, blank lines are ignored.

### Is the file case-sensitive?

No. Email addresses and domains are case-insensitive. `SPAM@EXAMPLE.COM` and `spam@example.com` are treated the same.

## Authentication Questions

### Why does a browser window open?

The tool uses modern OAuth authentication which requires browser-based login for security. This is the recommended method by Microsoft. The tool automatically detects and uses your default browser (Edge, Chrome, Firefox, or Brave).

### Can I use unattended/automated authentication?

For automation, you can use certificate-based authentication:

```powershell
Connect-ExchangeOnline -CertificateThumbprint "THUMBPRINT" -AppId "APP_ID" -Organization "tenant.onmicrosoft.com"
```

Then modify the script to skip the Connect-EXO function.

### Does the tool store my password?

No. OAuth authentication is used, which means no passwords are stored. Authentication tokens are managed by the PowerShell module.

### Can I use MFA with this tool?

Yes! Modern authentication supports Multi-Factor Authentication (MFA) automatically.

## Error Messages

### "Policy 'Spam' not found"

**Cause**: The spam policy doesn't exist in your Exchange Online.

**Solution**: Create it manually:
1. Go to [Exchange Admin Center](https://admin.exchange.microsoft.com)
2. Email & collaboration → Policies & rules → Threat policies
3. Anti-spam → Create policy → Inbound
4. Name it "Spam"

### "Module 'ExchangeOnlineManagement' not found"

**Cause**: PowerShell module not installed.

**Solution**:
```powershell
Install-Module -Name ExchangeOnlineManagement -Force
```

### "Access Denied" or "Unauthorized"

**Cause**: Insufficient permissions.

**Solution**: Verify you have Exchange Administrator role. Contact your Global Admin if needed.

### "Cannot be loaded because running scripts is disabled"

**Cause**: PowerShell execution policy restriction.

**Solution**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "File not found: C:\scripts\blocked.txt"

**Cause**: Default path doesn't exist or file is missing.

**Solution**: Either:
- Create the file: `New-Item -Path C:\scripts\blocked.txt -ItemType File -Force`
- Use custom path: `-BlockedTxtPath ".\blocked.txt"`

### "Maximum number of BlockedSenders exceeded"

**Cause**: You're trying to add more than 1,024 email addresses.

**Solution**:
- Use domain blocking instead of individual emails where possible
- Split into multiple policies
- Use Transport Rules for additional filtering

## Performance Questions

### How long does it take to run?

Typically 1-3 minutes depending on:
- Number of entries in your file
- Network speed
- Exchange Online responsiveness

### Can I run it during business hours?

Yes, but initial large imports might have brief service impact during propagation. Schedule large updates during off-peak hours.

### Does it impact email flow?

No direct impact. Email continues to flow normally during and after the update. New filtering rules apply to incoming emails after propagation.

## Advanced Questions

### Can I integrate this with SIEM/logging systems?

Yes, redirect output to syslog or file:

```powershell
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt" |
    Tee-Object -FilePath "spam-$(Get-Date -Format 'yyyy-MM-dd-HHmm').log"
```

### Can I run this as a scheduled task?

Yes! See [USAGE.md](USAGE.md) for detailed scheduled task examples.

### Can I use this with Azure Automation?

Yes, but you'll need to:
1. Use certificate-based authentication
2. Store blocked.txt in Azure Blob Storage or Automation Assets
3. Modify authentication in the script

### Can I extend this to manage other policies?

Yes! The script is modular. You can:
- Add allow list management
- Manage other anti-spam settings
- Integrate with Transport Rules
- Add custom logging

### How do I contribute improvements?

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Reporting bugs
- Suggesting features
- Submitting pull requests

## Troubleshooting Workflow

If you encounter issues, follow this workflow:

1. **Check Prerequisites**
   - PowerShell version: `$PSVersionTable.PSVersion`
   - Module installed: `Get-Module -ListAvailable ExchangeOnlineManagement`

2. **Verify Permissions**
   - Check your roles in Microsoft 365 Admin Center
   - Test manual connection: `Connect-ExchangeOnline`

3. **Test File**
   - File exists: `Test-Path .\blocked.txt`
   - File readable: `Get-Content .\blocked.txt`
   - Valid format: Check for special characters

4. **Review Logs**
   - Check output messages
   - Look for specific error codes
   - Note the failing operation

5. **Search for Solutions**
   - Check this FAQ
   - Review [USAGE.md](USAGE.md)
   - Search GitHub issues

6. **Get Help**
   - Create GitHub issue with:
     - Error message
     - PowerShell version
     - Module version: `(Get-Module ExchangeOnlineManagement).Version`
     - Steps to reproduce

## Still Need Help?

- **Documentation**: Check [README.md](README.md), [USAGE.md](USAGE.md), [INSTALL.md](INSTALL.md)
- **GitHub Issues**: [Create an issue](https://github.com/yourusername/exchange-spam-manager/issues)
- **PowerShell Help**: `Get-Help .\EXO-SpamManager.ps1 -Full`

---

**Didn't find your question?** Open an issue on GitHub and we'll add it to this FAQ!
