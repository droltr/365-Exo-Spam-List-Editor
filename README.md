# Exchange Online Spam Manager

A user-friendly PowerShell tool to manage Exchange Online spam filters by importing email addresses and domains from a text file.

## Features

- 🎯 **GUI Interface**: Easy-to-use Windows Forms interface with modern dark theme
- 📝 **Auto-Classification**: Automatically categorizes entries into emails and domains
- 🔄 **Incremental Updates**: Adds new entries without removing existing ones
- 🗑️ **Sync Mode**: Optional removal of entries not in the text file
- 📊 **Real-time Progress**: Live progress display in GUI and CLI
- 🌐 **Auto-Scope**: Automatically applies rules to all accepted domains
- 🔐 **Secure Authentication**: Uses modern OAuth authentication with Exchange Online
- 🎨 **Dark Theme**: Professional dark mode interface for reduced eye strain

## Prerequisites

- Windows PowerShell 5.1 or PowerShell 7+
- Exchange Online administrator permissions
- ExchangeOnlineManagement PowerShell module

## Installation

### Quick Install

1. **Clone the repository:**
```powershell
git clone https://github.com/yourusername/exchange-spam-manager.git
cd exchange-spam-manager
```

2. **Install Exchange Online module:**
```powershell
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
```

3. **Unblock downloaded scripts:**
```powershell
Get-ChildItem -Path . -Filter *.ps1 -Recurse | Unblock-File
```

4. **Create your blocked entries file:**
```powershell
Copy-Item blocked.example.txt blocked.txt
notepad blocked.txt
```

For detailed installation instructions, see [INSTALL.md](INSTALL.md).

## Quick Start

### GUI Mode (Recommended)

Simply run:
```powershell
.\Start-SpamManager.ps1
```

This will launch the GUI where you can:
1. Select your blocked entries file
2. Choose sync mode (optional)
3. Monitor progress in real-time
4. View summary results

### CLI Mode

For automation or advanced usage:

```powershell
# Basic usage (adds entries from blocked.txt)
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt"

# Sync mode (removes entries not in the file)
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt" -RemoveMissing

# Custom policy and rule names
.\EXO-SpamManager.ps1 -PolicyName "CustomSpam" -RuleName "CustomRule"
```

## File Format

The `blocked.txt` file supports multiple entry types:

```
# Email addresses (will be added to BlockedSenders)
spam@example.com
abuse@malicious.org

# Domains (will be added to BlockedSenderDomains)
spammer.com
*.malicious.net
phishing-site.org

# IP addresses (for future use)
192.168.1.100
203.0.113.50

# Comments (lines starting with # or ;)
# This is a comment
; This is also a comment

# Keywords section (for future use)
---keywords---
suspicious phrase
scam indicator
```

## How It Works

1. **File Parsing**: Reads the text file and classifies entries:
   - Valid email addresses → `BlockedSenders` list
   - Domain names (with or without wildcards) → `BlockedSenderDomains` list
   - Wildcards (*.domain.com) are converted to root domain (domain.com)

2. **Policy Update**:
   - Finds or creates the specified Hosted Content Filter Policy
   - Adds new entries incrementally
   - Optionally removes entries not in the file (with `-RemoveMissing`)

3. **Rule Management**:
   - Creates or updates the inbound filter rule
   - Applies to all accepted domains (excluding *.onmicrosoft.com)
   - Ensures the rule is enabled

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-BlockedTxtPath` | Path to the blocked entries file | `C:\scripts\blocked.txt` |
| `-PolicyName` | Name of the spam filter policy | `Spam` |
| `-RuleName` | Name of the inbound rule | `Spam (Inbound Rule)` |
| `-RemoveMissing` | Remove entries not in the file | `$false` |

## GUI Features

- **Modern Dark Theme**: Professional dark interface with reduced eye strain
- **File Browser**: Easy selection of blocked entries file
- **Sync Mode Toggle**: Visual checkbox for remove missing option
- **Real-time Logs**: Live output window showing all operations (Consolas font)
- **Progress Bar**: Visual progress indicator
- **Summary Display**: Results shown after completion
- **Color-Coded Messages**: Orange warnings, green success, red errors

## Security Notes

- The tool requires Exchange Online administrator permissions
- Uses modern OAuth authentication (no password storage)
- All operations are logged with timestamps
- Browser-based authentication opens in your default browser
- Supports Edge, Chrome, Firefox, and Brave browsers
- Automatic browser detection from Windows registry

## Troubleshooting

### Module Import Errors
If you see PackageManagement errors, run:
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name ExchangeOnlineManagement -Force -Scope CurrentUser
```

### Policy Not Found
Ensure the spam policy exists in Exchange Online admin center before running the script. Create it manually if needed.

### Authentication Issues
If authentication fails:
1. Ensure you have Exchange Online admin rights
2. Check your tenant allows PowerShell access
3. Verify ExchangeOnlineManagement module is up to date

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Roadmap

- [ ] IP address blocking support
- [ ] Keyword-based filtering via Transport Rules
- [ ] Multiple policy management
- [ ] Export current blocked lists
- [ ] Scheduled task automation
- [ ] Email notification on completion

## Author

Created for Exchange Online administrators who need efficient spam management.

## Disclaimer

This tool modifies Exchange Online spam filtering policies. Always test in a non-production environment first. The authors are not responsible for any misconfiguration or data loss.
