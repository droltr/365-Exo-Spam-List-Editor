# Exchange Online Management Module Installation

## Quick Install Guide

### Step 1: Open PowerShell as Administrator

Right-click PowerShell icon → "Run as Administrator"

### Step 2: Install the Module

```powershell
# Set TLS 1.2 (required for module installation)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install the module
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Scope CurrentUser
```

### Step 3: Verify Installation

```powershell
Get-Module -ListAvailable ExchangeOnlineManagement
```

You should see:
```
ModuleType Version    Name
---------- -------    ----
Script     3.x.x      ExchangeOnlineManagement
```

### Step 4: Test Connection (Optional)

```powershell
# Import the module
Import-Module ExchangeOnlineManagement

# Test connection (Firefox will open for login)
Connect-ExchangeOnline

# Disconnect when done
Disconnect-ExchangeOnline -Confirm:$false
```

## What Happens During Connection?

1. **Browser Opens**: Your default browser (Firefox) will automatically open
2. **Login Page**: You'll see `login.microsoftonline.com`
3. **Enter Credentials**:
   - Email: your-email@company.com
   - Password: your password
   - MFA: Approve on Authenticator app (if enabled)
4. **Browser Closes**: After successful auth, browser closes automatically
5. **PowerShell Connected**: You're now connected to Exchange Online

## Troubleshooting

### Error: "Install-Module is not recognized"

**Solution**: Install PowerShellGet first:
```powershell
Install-Module -Name PowerShellGet -Force -AllowClobber
```

### Error: "Unable to download from URI"

**Solution**: Update TLS settings:
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

### Error: "Package 'ExchangeOnlineManagement' failed to install"

**Solution**: Use `-Scope CurrentUser` to avoid admin requirements:
```powershell
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
```

### Error: "Access Denied" during connection

**Solution**: Ensure you have one of these roles:
- Global Administrator
- Exchange Administrator
- Security Administrator

## After Installation

Once installed, run the spam manager:

```powershell
cd F:\Data\Coding\Spam
.\EXO-SpamManager.ps1 -BlockedTxtPath "blocked.txt"
```

**Expected behavior:**
1. Script starts
2. Firefox opens automatically
3. Login page appears
4. You authenticate
5. Script updates spam policies
6. Summary is displayed

## Alternative: GUI Mode

You can also use the GUI launcher:

```powershell
.\Start-SpamManager.ps1
```

Then:
1. Select your blocked.txt file
2. Click "Start"
3. Firefox will open for authentication
4. Watch progress in real-time

---

**Note**: If you don't have Exchange Online admin access, you won't be able to test the real connection. The simulation test is sufficient to verify the code logic works correctly.
