# Installation Guide

This guide will help you install and configure the Exchange Online Spam Manager.

## System Requirements

- **Operating System**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: Version 5.1 or later (PowerShell 7+ recommended)
- **Permissions**: Exchange Online Administrator role
- **Internet**: Active internet connection for Exchange Online

## Step-by-Step Installation

### 1. Check PowerShell Version

Open PowerShell and run:
```powershell
$PSVersionTable.PSVersion
```

You should see version 5.1 or higher.

### 2. Install Exchange Online Management Module

Open PowerShell **as Administrator** and run:

```powershell
# Set TLS 1.2 for secure connection
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install the module
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Scope AllUsers
```

If you don't have administrator rights, install for current user only:
```powershell
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Scope CurrentUser
```

### 3. Download the Tool

**Option A: Using Git**
```powershell
cd C:\
git clone https://github.com/yourusername/exchange-spam-manager.git
cd exchange-spam-manager
```

**Option B: Manual Download**
1. Download the ZIP file from GitHub
2. Extract to `C:\exchange-spam-manager`
3. Open PowerShell and navigate to the folder:
   ```powershell
   cd C:\exchange-spam-manager
   ```

### 4. Unblock Scripts

PowerShell blocks downloaded scripts by default. Unblock them:

```powershell
Get-ChildItem -Path . -Filter *.ps1 -Recurse | Unblock-File
```

### 5. Set Execution Policy (If Needed)

If you encounter execution policy errors:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 6. Create Your Blocked Entries File

Copy the example file and customize it:

```powershell
Copy-Item blocked.example.txt blocked.txt
notepad blocked.txt
```

Add your spam email addresses and domains to the file.

### 7. Create Spam Policy in Exchange Online (One-time Setup)

**Important**: The script requires an existing spam policy named "Spam" (or custom name).

1. Go to [Exchange Admin Center](https://admin.exchange.microsoft.com)
2. Navigate to: **Email & collaboration** > **Policies & rules** > **Threat policies**
3. Click **Anti-spam** under **Policies**
4. Click **+ Create policy** > **Inbound**
5. Name it: `Spam`
6. Configure basic settings as needed
7. Click **Create**

### 8. Test the Installation

Run the GUI:
```powershell
.\Start-SpamManager.ps1
```

Or test CLI mode:
```powershell
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt"
```

## Troubleshooting

### Error: "ExchangeOnlineManagement module not found"

**Solution:**
```powershell
Import-Module ExchangeOnlineManagement
```

If this fails, reinstall the module:
```powershell
Install-Module -Name ExchangeOnlineManagement -Force
```

### Error: "Policy 'Spam' not found"

**Solution:** Create the policy manually in Exchange Admin Center (see Step 7).

### Error: "Access Denied" or "Insufficient Permissions"

**Solution:** Ensure you have one of these roles:
- Global Administrator
- Exchange Administrator
- Security Administrator

Check your roles at [Microsoft 365 Admin Center](https://admin.microsoft.com).

### Error: "Cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Authentication Issues

**Solution:**
1. Ensure Modern Authentication is enabled in your tenant
2. Clear browser cache and cookies
3. Try a different browser
4. Update ExchangeOnlineManagement module:
   ```powershell
   Update-Module -Name ExchangeOnlineManagement
   ```

### GUI Doesn't Launch

**Solution:**
1. Check if .NET Framework 4.5+ is installed
2. Run from PowerShell directly (not PowerShell ISE)
3. Try CLI mode instead:
   ```powershell
   .\EXO-SpamManager.ps1
   ```

## Upgrading

To update to the latest version:

**Using Git:**
```powershell
cd C:\exchange-spam-manager
git pull
```

**Manual:**
1. Download the latest release
2. Extract and replace old files
3. Keep your `blocked.txt` file

## Uninstallation

To remove the tool:

```powershell
# Remove the folder
Remove-Item -Path C:\exchange-spam-manager -Recurse -Force

# Optionally remove the PowerShell module
Uninstall-Module -Name ExchangeOnlineManagement
```

## Next Steps

- Read the [README.md](README.md) for usage instructions
- Review [USAGE.md](USAGE.md) for advanced scenarios
- Check [FAQ.md](FAQ.md) for common questions

## Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Review the error messages in the output window
3. Search existing GitHub issues
4. Create a new issue with error details

## Security Notes

- Never commit your `blocked.txt` file to version control if it contains sensitive data
- The tool uses OAuth authentication (no password storage)
- All connections use TLS encryption
- Review the code before running in production

## Scheduled Automation (Optional)

To run the tool automatically:

1. Create a scheduled task:
```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\exchange-spam-manager\EXO-SpamManager.ps1 -BlockedTxtPath C:\exchange-spam-manager\blocked.txt"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
Register-ScheduledTask -TaskName "Exchange Spam Manager" -Action $action -Trigger $trigger -Principal $principal
```

2. Adjust the schedule as needed in Task Scheduler.

---

**Installation complete!** You're ready to manage your Exchange Online spam filters efficiently.
