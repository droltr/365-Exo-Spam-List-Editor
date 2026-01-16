<#
.SYNOPSIS
    Exchange Online Authentication Functions

.DESCRIPTION
    Handles connection to Exchange Online using multiple authentication methods
#>

function Ensure-Module {
    param([string]$Name)

    # Check if module is already loaded
    if (Get-Module -Name $Name) {
        return
    }

    # Try to import quietly
    Import-Module $Name -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    # Verify critical commands are available and check version compatibility
    if ($Name -eq 'ExchangeOnlineManagement') {
        if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
            throw "ExchangeOnlineManagement module not available. Please install: Install-Module ExchangeOnlineManagement"
        }
        
        # Module version compatibility checking
        try {
            $module = Get-Module -Name ExchangeOnlineManagement -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
            if ($module.Version -lt [version]"3.0.0") {
                Write-Warning "ExchangeOnlineManagement module version $($module.Version) detected. Consider updating to version 3.0.0 or higher for best compatibility."
            }
        } catch {
            Write-Info "Could not check module version: $($_.Exception.Message)"
        }
    }
}

function Connect-EXO {
    <#
    .SYNOPSIS
        Connects to Exchange Online using OAuth authentication
    .DESCRIPTION
        Checks for existing connection or establishes new one.
        Tries multiple authentication methods for reliability.
    #>

    Write-Progress -Activity 'Connecting' -Status 'Checking Exchange Online connection...' -PercentComplete 5

    # Ensure module is installed
    try {
        Ensure-Module -Name ExchangeOnlineManagement
    } catch {
        Write-Info "Attempting to install ExchangeOnlineManagement module..."
        try {
            Install-Module -Name ExchangeOnlineManagement -Force -Scope CurrentUser -ErrorAction Stop
            Write-Info "Module installed successfully."
        } catch {
            throw "Failed to install ExchangeOnlineManagement module: $($_.Exception.Message)"
        }
    }

    # Check if already connected
    $existingSession = Get-PSSession | Where-Object {
        $_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.State -eq 'Opened'
    }

    if ($existingSession) {
        Write-Info "Using existing Exchange Online connection."
        return
    }

    Write-Info "Connecting to Exchange Online..."

    # Try authentication methods in order
    $authMethods = @(
        @{
            Name = "Device Code Authentication"
            Params = @{
                Device = $true
                ShowBanner = $false
                ErrorAction = 'Stop'
            }
        },
        @{
            Name = "Interactive Authentication"
            Params = @{
                ShowBanner = $false
                ErrorAction = 'Stop'
            }
        }
    )

    $connected = $false
    foreach ($method in $authMethods) {
        try {
            Write-Info "Trying: $($method.Name)..."
            $params = $method.Params
            Connect-ExchangeOnline @params
            Write-Info "Connected successfully using $($method.Name)."
            $connected = $true
            break
        } catch {
            Write-Info "Failed to connect using $($method.Name): $($_.Exception.Message)"
            continue
        }
    }

    if (-not $connected) {
        throw "All connection methods failed. Please ensure:`n" +
              "1. ExchangeOnlineManagement module is installed`n" +
              "2. You have Exchange Online administrator permissions`n" +
              "3. Your account has MFA enabled (if required)`n" +
              "4. Network connectivity is available"
    }

    # Connection validation and health checks
    Write-Progress -Activity 'Connecting' -Status 'Validating connection...' -PercentComplete 95
    try {
        # Test connection by getting organization config
        $orgConfig = Get-OrganizationConfig -ErrorAction Stop
        Write-Info "Connection validated successfully."
        
        # Health check - verify we can access basic Exchange objects
        $testMailbox = Get-Mailbox -ResultSize 1 -ErrorAction SilentlyContinue
        if ($testMailbox) {
            Write-Info "Health check passed - Exchange Online access confirmed."
        } else {
            Write-Warning "Health check warning - could not access mailbox objects. Some operations may be restricted."
        }
    } catch {
        Write-Warning "Connection validation failed: $($_.Exception.Message)"
        throw "Connection established but validation failed. Please check permissions."
    }
}



function Disconnect-EXO {
    <#
    .SYNOPSIS
        Disconnects from Exchange Online
    .DESCRIPTION
        Safely disconnects the current Exchange Online session
    #>
    
    Write-Info "Disconnecting from Exchange Online..."
    
    try {
        # Check if connected
        $session = Get-PSSession | Where-Object {
            $_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.State -eq 'Opened'
        }
        
        if ($session) {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction Stop
            Write-Info "Successfully disconnected from Exchange Online."
        } else {
            Write-Info "No active Exchange Online session found."
        }
    } catch {
        Write-Warning "Error during disconnection: $($_.Exception.Message)"
        throw
    }
}