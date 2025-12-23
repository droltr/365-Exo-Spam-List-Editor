<#
.SYNOPSIS
    GUI Interface Functions

.DESCRIPTION
    Provides Windows Forms GUI for the Exchange Online Spam Manager
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import common utilities
. "$PSScriptRoot\Common-Utils.ps1"

function Write-LogMessage {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message"
}

function Test-ExchangeOnlineConnection {
    <#
    .SYNOPSIS
        Tests if connected to Exchange Online
    #>
    try {
        $session = Get-PSSession | Where-Object {
            $_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.State -eq 'Opened'
        }
        if ($session) { return $true }

        # Alternative check - try to run a simple cmdlet
        $null = Get-Command Get-HostedContentFilterPolicy -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Export-SelectedRules {
    param([switch]$EOPSenders, [switch]$EOPDomains, [switch]$TransportRules)
    
    # Check connection first
    Write-Host "[EXPORT] Checking Exchange Online connection..." -ForegroundColor Cyan
    try {
        # Test connection by trying to get a simple cmdlet
        $testCmdlet = Get-Command Get-HostedContentFilterPolicy -ErrorAction Stop
        Write-Host "[EXPORT] [OK] Connection verified" -ForegroundColor Green
    } catch {
        throw "Not connected to Exchange Online. Please login first. Error: $($_.Exception.Message)"
    }
    
    Write-Host "[EXPORT] Starting export process..." -ForegroundColor Cyan
    $exportData = @()
    $exportData += "# Exported from Exchange Online Spam Manager"
    $exportData += "# Date: $(Get-Date)"
    $exportData += ""
    
    try {
        if ($EOPSenders) {
            Write-Host "[EXPORT] Exporting EOP Blocked Senders..." -ForegroundColor Yellow
            $policy = Get-HostedContentFilterPolicy -Identity "Spam" -ErrorAction Stop
            if ($policy -and $policy.BlockedSenders) {
                $exportData += "EMAIL ADDRESSES"
                foreach ($sender in $policy.BlockedSenders) {
                    if ($sender) { 
                        $exportData += $sender
                        Write-Host "[EXPORT]   Added: $sender" -ForegroundColor Gray
                    }
                }
                Write-Host "[EXPORT] [OK] Exported $($policy.BlockedSenders.Count) senders" -ForegroundColor Green
            } else {
                Write-Host "[EXPORT] [!] No blocked senders found" -ForegroundColor Yellow
            }
            $exportData += ""
        }
        
        if ($EOPDomains) {
            Write-Host "[EXPORT] Exporting EOP Blocked Domains..." -ForegroundColor Yellow
            $policy = Get-HostedContentFilterPolicy -Identity "Spam" -ErrorAction Stop
            if ($policy -and $policy.BlockedSenderDomains) {
                $exportData += "DOMAINS"
                foreach ($domain in $policy.BlockedSenderDomains) {
                    if ($domain) { 
                        $exportData += $domain
                        Write-Host "[EXPORT]   Added: $domain" -ForegroundColor Gray
                    }
                }
                Write-Host "[EXPORT] [OK] Exported $($policy.BlockedSenderDomains.Count) domains" -ForegroundColor Green
            } else {
                Write-Host "[EXPORT] [!] No blocked domains found" -ForegroundColor Yellow
            }
            $exportData += ""
        }
        
        if ($TransportRules) {
            Write-Host "[EXPORT] Exporting Transport Rules..." -ForegroundColor Yellow
            $exportData += "---keywords---"
            # Get transport rules for keywords
            $keywordRule = Get-TransportRule -Identity "Blocked Words" -ErrorAction SilentlyContinue
            if ($keywordRule -and $keywordRule.SubjectOrBodyContainsWords) {
                foreach ($keyword in $keywordRule.SubjectOrBodyContainsWords) {
                    if ($keyword) { 
                        $exportData += $keyword
                        Write-Host "[EXPORT]   Added keyword: $keyword" -ForegroundColor Gray
                    }
                }
                Write-Host "[EXPORT] [OK] Exported $($keywordRule.SubjectOrBodyContainsWords.Count) keywords" -ForegroundColor Green
            } else {
                Write-Host "[EXPORT] [!] No transport rule keywords found" -ForegroundColor Yellow
            }
        }
        
        Write-Host "[EXPORT] Export completed successfully" -ForegroundColor Green
        return $exportData -join "`n"
    } catch {
        Write-Host "[EXPORT] [X] Export failed: $($_.Exception.Message)" -ForegroundColor Red
        throw "Export failed: $($_.Exception.Message)"
    }
}

function Import-FileToSelectedRules {
    param([string]$FilePath, [switch]$EOPSenders, [switch]$EOPDomains, [switch]$TransportRules)
    
    # Check connection first
    Write-Host "[IMPORT] Checking Exchange Online connection..." -ForegroundColor Cyan
    try {
        # Test connection by trying to get a simple cmdlet
        $testCmdlet = Get-Command Get-HostedContentFilterPolicy -ErrorAction Stop
        Write-Host "[IMPORT] [OK] Connection verified" -ForegroundColor Green
    } catch {
        throw "Not connected to Exchange Online. Please login first. Error: $($_.Exception.Message)"
    }
    
    Write-Host "[IMPORT] Starting import process from: $FilePath" -ForegroundColor Cyan
    
    # Import and parse file
    . "$PSScriptRoot\Parse-BlockedFile.ps1"
    $lines = Read-Lines -Path $FilePath
    $data = Classify -Lines $lines
    
    $result = "Import Results:`n"
    
    try {
        if ($EOPSenders -and $data.Emails.Count -gt 0) {
            Write-Host "[IMPORT] Updating EOP Blocked Senders..." -ForegroundColor Yellow
            Write-Host "[IMPORT]   Adding $($data.Emails.Count) senders" -ForegroundColor Gray
            . "$PSScriptRoot\Update-EOPPolicy.ps1"
            Update-BlockedLists -PolicyName "Spam" -Emails $data.Emails
            $result += "- Added $($data.Emails.Count) emails to EOP Blocked Senders`n"
            Write-Host "[IMPORT] [OK] EOP senders updated" -ForegroundColor Green
        }
        
        if ($EOPDomains -and $data.Domains.Count -gt 0) {
            Write-Host "[IMPORT] Updating EOP Blocked Domains..." -ForegroundColor Yellow
            Write-Host "[IMPORT]   Adding $($data.Domains.Count) domains" -ForegroundColor Gray
            . "$PSScriptRoot\Update-EOPPolicy.ps1"
            Update-BlockedLists -PolicyName "Spam" -Domains $data.Domains
            $result += "- Added $($data.Domains.Count) domains to EOP Blocked Domains`n"
            Write-Host "[IMPORT] [OK] EOP domains updated" -ForegroundColor Green
        }
        
        if ($TransportRules -and ($data.Emails.Count -gt 0 -or $data.Domains.Count -gt 0 -or $data.Keywords.Count -gt 0)) {
            Write-Host "[IMPORT] Updating Transport Rules..." -ForegroundColor Yellow
            Write-Host "[IMPORT]   Adding $($data.Emails.Count) emails, $($data.Domains.Count) domains, $($data.Keywords.Count) keywords" -ForegroundColor Gray
            . "$PSScriptRoot\Update-TransportRule.ps1"
            Create-OrUpdateRule -RuleName "Blocked Emails" -Emails $data.Emails -Domains $data.Domains -Keywords $data.Keywords
            $result += "- Updated Transport Rules with $($data.Emails.Count) emails, $($data.Domains.Count) domains, $($data.Keywords.Count) keywords`n"
            Write-Host "[IMPORT] [OK] Transport rules updated" -ForegroundColor Green
        }
        
        $result += "`nImport completed successfully!"
        Write-Host "[IMPORT] Import completed successfully" -ForegroundColor Green
        return $result
    } catch {
        Write-Host "[IMPORT] [X] Import failed: $($_.Exception.Message)" -ForegroundColor Red
        throw "Import failed: $($_.Exception.Message)"
    }
}

function Connect-EXOWithUI {
    <#
    .SYNOPSIS
        Connects to Exchange Online with UI feedback
    #>
    Write-LogMessage "Starting Exchange Online connection process..."

    try {
        # Ensure module exists
        if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
            Write-LogMessage "Installing ExchangeOnlineManagement module..."
            Install-Module -Name ExchangeOnlineManagement -Force -Scope CurrentUser -ErrorAction Stop
        }

        # Check for existing session
        $session = Get-PSSession | Where-Object {
            $_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.State -eq 'Opened'
        }

        if ($session) {
            Write-LogMessage "Using existing Exchange Online session"
            return $true
        }

        # Connect with device code auth (opens full browser)
        Write-LogMessage "Opening Exchange Online login page in your default browser..."
        Write-LogMessage "Please sign in with your Exchange Online administrator account"
        Write-LogMessage "After signing in, return to this application"

        Connect-ExchangeOnline -Device -ErrorAction Stop
        Write-LogMessage "Successfully connected to Exchange Online!"
        return $true
    }
    catch {
        Write-LogMessage "Connection error: $($_.Exception.Message)"
        Write-LogMessage "Please try again or contact your administrator"
        return $false
    }
}

# Update-ConnectionStatus will be defined inside Start-GUI to have access to form controls

function Start-GUI {
    # Enable Visual Styles for modern look
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

    # Professional dark theme colors
    $bgDark = [System.Drawing.Color]::FromArgb(25, 25, 25)      # Darker background
    $bgMedium = [System.Drawing.Color]::FromArgb(35, 35, 35)    # Medium gray panels
    $bgLight = [System.Drawing.Color]::FromArgb(45, 45, 45)     # Light gray accents
    $textColor = [System.Drawing.Color]::FromArgb(255, 255, 255) # Pure white text
    $textGray = [System.Drawing.Color]::FromArgb(180, 180, 180)  # Light gray text
    $accentBlue = [System.Drawing.Color]::FromArgb(0, 122, 204)  # Professional blue
    $accentGreen = [System.Drawing.Color]::FromArgb(0, 184, 148) # Success green
    $accentRed = [System.Drawing.Color]::FromArgb(220, 53, 69)   # Error red
    $borderColor = [System.Drawing.Color]::FromArgb(55, 55, 55)  # Subtle borders

    # Set up form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Exchange Online Spam Manager'
    $form.Size = New-Object System.Drawing.Size(700, 750)
    $form.MinimumSize = New-Object System.Drawing.Size(700, 750)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'Sizable'
    $form.MaximizeBox = $true
    $form.MinimizeBox = $true
    $form.BackColor = $bgDark

    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(560, 30)
    $titleLabel.Text = 'Exchange Online Spam Filter Manager'
    $titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $textColor
    $titleLabel.BackColor = $bgDark
    $form.Controls.Add($titleLabel)

    # Subtitle label
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Location = New-Object System.Drawing.Point(20, 55)
    $subtitleLabel.Size = New-Object System.Drawing.Size(560, 20)
    $subtitleLabel.Text = 'Import blocked senders and domains from a text file'
    $subtitleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $subtitleLabel.ForeColor = $textGray
    $subtitleLabel.BackColor = $bgDark
    $form.Controls.Add($subtitleLabel)

    # File selection group
    $fileGroupBox = New-Object System.Windows.Forms.GroupBox
    $fileGroupBox.Location = New-Object System.Drawing.Point(20, 90)
    $fileGroupBox.Size = New-Object System.Drawing.Size(660, 80)
    $fileGroupBox.Text = 'File Selection'
    $fileGroupBox.ForeColor = $textColor
    $fileGroupBox.BackColor = $bgMedium
    $fileGroupBox.FlatStyle = 'Flat'
    $form.Controls.Add($fileGroupBox)

    # File path label
    $fileLabel = New-Object System.Windows.Forms.Label
    $fileLabel.Location = New-Object System.Drawing.Point(10, 25)
    $fileLabel.Size = New-Object System.Drawing.Size(100, 20)
    $fileLabel.Text = 'Blocked File:'
    $fileLabel.ForeColor = $textColor
    $fileLabel.BackColor = $bgDark
    $fileGroupBox.Controls.Add($fileLabel)

    # File path textbox
    $fileTextBox = New-Object System.Windows.Forms.TextBox
    $fileTextBox.Location = New-Object System.Drawing.Point(10, 45)
    $fileTextBox.Size = New-Object System.Drawing.Size(500, 20)
    $fileTextBox.Text = '.\blocked.txt'
    $fileTextBox.BackColor = $bgMedium
    $fileTextBox.ForeColor = $textColor
    $fileTextBox.BorderStyle = 'FixedSingle'
    $fileGroupBox.Controls.Add($fileTextBox)

    # Browse button
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(520, 43)
    $browseButton.Size = New-Object System.Drawing.Size(100, 25)
    $browseButton.Text = 'Browse...'
    $browseButton.BackColor = $bgLight
    $browseButton.ForeColor = $textColor
    $browseButton.FlatStyle = 'Flat'
    $browseButton.FlatAppearance.BorderColor = $textGray
    $browseButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = 'Text files (*.txt)|*.txt|All files (*.*)|*.*'
        $openFileDialog.Title = 'Select Blocked Entries File'
        $openFileDialog.InitialDirectory = $PSScriptRoot

        if ($openFileDialog.ShowDialog() -eq 'OK') {
            $fileTextBox.Text = $openFileDialog.FileName
        }
    })
    $fileGroupBox.Controls.Add($browseButton)

    # Define Update-ConnectionStatus as a script block (will be used after controls are created)
    $script:UpdateConnectionStatusBlock = {
        if (Test-ExchangeOnlineConnection) {
            $connectionLabel.Text = 'OK'
            $connectionLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 184, 148)
            $statusLabel.Text = 'Connected to Exchange Online'
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 184, 148)
            $startButton.Enabled = $true
            $loginButton.Enabled = $false
            $logoutButton.Enabled = $true
        } else {
            $connectionLabel.Text = 'X'
            $connectionLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
            $statusLabel.Text = 'Not connected'
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
            $startButton.Enabled = $false
            $loginButton.Enabled = $true
            $logoutButton.Enabled = $false
        }
    }

    # Connection buttons
    $loginButton = New-Object System.Windows.Forms.Button
    $loginButton.Location = New-Object System.Drawing.Point(20, 180)
    $loginButton.Size = New-Object System.Drawing.Size(100, 30)
    $loginButton.Text = 'Login'
    $loginButton.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
    $loginButton.ForeColor = [System.Drawing.Color]::White
    $loginButton.FlatStyle = 'Flat'
    $loginButton.FlatAppearance.BorderSize = 0
    $loginButton.Add_Click({
        $outputTextBox.AppendText("`n[LOGIN] Connecting to Exchange Online...`n")
        $outputTextBox.AppendText("A code will appear - copy it, then sign in via browser.`n")
        $statusLabel.Text = 'Connecting to Exchange Online...'
        $statusLabel.ForeColor = $accentBlue
        $form.Refresh()

        try {
            # Try Device Code Flow first
            Connect-ExchangeOnline -Device -ShowBanner:$false -ErrorAction Stop
            $outputTextBox.AppendText("[LOGIN] Connection established, verifying...`n")

            # Verify connection with our test function
            if (Test-ExchangeOnlineConnection) {
                & $script:UpdateConnectionStatusBlock
                $outputTextBox.AppendText("[SUCCESS] Connected successfully!`n")
            } else {
                throw "Connection verification failed"
            }
        } catch {
            $err = $_.Exception.Message
            if ($err -match "parameter.*Device") {
                $outputTextBox.AppendText("[LOGIN] Device parameter not supported, trying interactive mode...`n")
                try {
                    Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
                    if (Test-ExchangeOnlineConnection) {
                        & $script:UpdateConnectionStatusBlock
                        $outputTextBox.AppendText("[SUCCESS] Connected successfully!`n")
                        return
                    }
                } catch {
                    $err = $_.Exception.Message
                }
            }
            
            $connectionLabel.Text = 'X'
            $connectionLabel.ForeColor = $accentRed
            $statusLabel.Text = 'Connection failed'
            $statusLabel.ForeColor = $accentRed
            $startButton.Enabled = $false
            $outputTextBox.AppendText("[LOGIN] Connection failed: $err`n")
        }
    })
    $form.Controls.Add($loginButton)

    $logoutButton = New-Object System.Windows.Forms.Button
    $logoutButton.Location = New-Object System.Drawing.Point(130, 180)
    $logoutButton.Size = New-Object System.Drawing.Size(100, 30)
    $logoutButton.Text = 'Logout'
    $logoutButton.BackColor = [System.Drawing.Color]::FromArgb(150, 0, 0)
    $logoutButton.ForeColor = [System.Drawing.Color]::White
    $logoutButton.FlatStyle = 'Flat'
    $logoutButton.FlatAppearance.BorderSize = 0
    $logoutButton.Enabled = $false
    $logoutButton.Add_Click({
        $outputTextBox.AppendText("`n[LOGOUT] Disconnecting from Exchange Online...`n")
        
        try {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction Stop
            & $script:UpdateConnectionStatusBlock
            $outputTextBox.AppendText("[LOGOUT] Disconnected successfully!`n")
        } catch {
            $outputTextBox.AppendText("[LOGOUT] Disconnect failed: $($_.Exception.Message)`n")
        }
    })
    $form.Controls.Add($logoutButton)

    # Rule Selection group
    $ruleGroupBox = New-Object System.Windows.Forms.GroupBox
    $ruleGroupBox.Location = New-Object System.Drawing.Point(20, 220)
    $ruleGroupBox.Size = New-Object System.Drawing.Size(660, 120)
    $ruleGroupBox.Text = 'Rule Selection'
    $ruleGroupBox.ForeColor = $textColor
    $ruleGroupBox.BackColor = $bgMedium
    $ruleGroupBox.FlatStyle = 'Flat'
    $form.Controls.Add($ruleGroupBox)

    # EOP Blocked Senders checkbox
    $eopSendersCheckBox = New-Object System.Windows.Forms.CheckBox
    $eopSendersCheckBox.Location = New-Object System.Drawing.Point(10, 25)
    $eopSendersCheckBox.Size = New-Object System.Drawing.Size(300, 20)
    $eopSendersCheckBox.Text = 'EOP Blocked Senders'
    $eopSendersCheckBox.Checked = $true
    $eopSendersCheckBox.ForeColor = $textColor
    $eopSendersCheckBox.BackColor = $bgDark
    $ruleGroupBox.Controls.Add($eopSendersCheckBox)

    # EOP Blocked Domains checkbox
    $eopDomainsCheckBox = New-Object System.Windows.Forms.CheckBox
    $eopDomainsCheckBox.Location = New-Object System.Drawing.Point(10, 45)
    $eopDomainsCheckBox.Size = New-Object System.Drawing.Size(300, 20)
    $eopDomainsCheckBox.Text = 'EOP Blocked Domains'
    $eopDomainsCheckBox.Checked = $true
    $eopDomainsCheckBox.ForeColor = $textColor
    $eopDomainsCheckBox.BackColor = $bgDark
    $ruleGroupBox.Controls.Add($eopDomainsCheckBox)

    # Transport Rules checkbox
    $transportRulesCheckBox = New-Object System.Windows.Forms.CheckBox
    $transportRulesCheckBox.Location = New-Object System.Drawing.Point(10, 65)
    $transportRulesCheckBox.Size = New-Object System.Drawing.Size(300, 20)
    $transportRulesCheckBox.Text = 'Transport Rules (Emails, Domains, Keywords)'
    $transportRulesCheckBox.Checked = $true
    $transportRulesCheckBox.ForeColor = $textColor
    $transportRulesCheckBox.BackColor = $bgDark
    $ruleGroupBox.Controls.Add($transportRulesCheckBox)

    # Download button
    $downloadButton = New-Object System.Windows.Forms.Button
    $downloadButton.Location = New-Object System.Drawing.Point(380, 25)
    $downloadButton.Size = New-Object System.Drawing.Size(120, 30)
    $downloadButton.Text = 'Download Rules'
    $downloadButton.BackColor = $accentBlue
    $downloadButton.ForeColor = [System.Drawing.Color]::White
    $downloadButton.FlatStyle = 'Flat'
    $downloadButton.FlatAppearance.BorderSize = 0
    $downloadButton.Add_Click({
        # Check connection first
        $outputTextBox.AppendText("`n[DOWNLOAD] Checking Exchange Online connection...`n")
        try {
            # Test connection by trying to get a simple cmdlet
            $testCmdlet = Get-Command Get-HostedContentFilterPolicy -ErrorAction Stop
            $outputTextBox.AppendText("[DOWNLOAD] [OK] Connection verified`n")
        } catch {
            $outputTextBox.AppendText("[DOWNLOAD] [X] Connection check failed: $($_.Exception.Message)`n")
            [System.Windows.Forms.MessageBox]::Show(
                "Not connected to Exchange Online. Please click Login first.`nError: $($_.Exception.Message)",
                'Connection Required',
                'OK',
                'Error'
            )
            return
        }
        
        # Check if any rule is selected
        if (-not ($eopSendersCheckBox.Checked -or $eopDomainsCheckBox.Checked -or $transportRulesCheckBox.Checked)) {
            [System.Windows.Forms.MessageBox]::Show(
                'Please select at least one rule type to download.',
                'No Selection',
                'OK',
                'Warning'
            )
            return
        }

        # Show save file dialog
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.Filter = 'Text files (*.txt)|*.txt|All files (*.*)|*.*'
        $saveFileDialog.Title = 'Save Blocked Lists'
        $saveFileDialog.FileName = 'blocked_lists.txt'

        if ($saveFileDialog.ShowDialog() -eq 'OK') {
            $outputTextBox.AppendText("[DOWNLOAD] Exporting selected rules to: $($saveFileDialog.FileName)`n")
            
            try {
                # Export selected rules
                $exportedData = Export-SelectedRules -EOPSenders:$eopSendersCheckBox.Checked -EOPDomains:$eopDomainsCheckBox.Checked -TransportRules:$transportRulesCheckBox.Checked
                $exportedData | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
                $outputTextBox.AppendText("[DOWNLOAD] Successfully exported rules`n")
                
                [System.Windows.Forms.MessageBox]::Show(
                    "Rules exported successfully to:`n$($saveFileDialog.FileName)",
                    'Export Complete',
                    'OK',
                    'Information'
                )
            } catch {
                $outputTextBox.AppendText("[DOWNLOAD] [X] Export failed: $($_.Exception.Message)`n")
                [System.Windows.Forms.MessageBox]::Show(
                    "Export failed: $($_.Exception.Message)",
                    'Export Error',
                    'OK',
                    'Error'
                )
            }
        }
    })
    $ruleGroupBox.Controls.Add($downloadButton)

    # Upload button
    $uploadButton = New-Object System.Windows.Forms.Button
    $uploadButton.Location = New-Object System.Drawing.Point(510, 25)
    $uploadButton.Size = New-Object System.Drawing.Size(120, 30)
    $uploadButton.Text = 'Upload File'
    $uploadButton.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
    $uploadButton.ForeColor = [System.Drawing.Color]::White
    $uploadButton.FlatStyle = 'Flat'
    $uploadButton.FlatAppearance.BorderSize = 0
    $uploadButton.Add_Click({
        # Check connection first
        $outputTextBox.AppendText("`n[UPLOAD] Checking Exchange Online connection...`n")
        try {
            # Test connection by trying to get a simple cmdlet
            $testCmdlet = Get-Command Get-HostedContentFilterPolicy -ErrorAction Stop
            $outputTextBox.AppendText("[UPLOAD] [OK] Connection verified`n")
        } catch {
            $outputTextBox.AppendText("[UPLOAD] [X] Connection check failed: $($_.Exception.Message)`n")
            [System.Windows.Forms.MessageBox]::Show(
                "Not connected to Exchange Online. Please click Login first.`nError: $($_.Exception.Message)",
                'Connection Required',
                'OK',
                'Error'
            )
            return
        }
        
        # Check if any rule is selected
        if (-not ($eopSendersCheckBox.Checked -or $eopDomainsCheckBox.Checked -or $transportRulesCheckBox.Checked)) {
            [System.Windows.Forms.MessageBox]::Show(
                'Please select at least one rule type to update.',
                'No Selection',
                'OK',
                'Warning'
            )
            return
        }

        # Validate file path
        if (-not (Test-Path -LiteralPath $fileTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                "File not found: $($fileTextBox.Text)`n`nPlease select a valid file.",
                'File Not Found',
                'OK',
                'Error'
            )
            return
        }

        $outputTextBox.AppendText("[UPLOAD] Importing file to selected rules...`n")
        
        try {
            # Import file and update selected rules
            $result = Import-FileToSelectedRules -FilePath $fileTextBox.Text -EOPSenders:$eopSendersCheckBox.Checked -EOPDomains:$eopDomainsCheckBox.Checked -TransportRules:$transportRulesCheckBox.Checked
            $outputTextBox.AppendText("[UPLOAD] Successfully updated rules`n")
            
            [System.Windows.Forms.MessageBox]::Show(
                $result,
                'Import Complete',
                'OK',
                'Information'
            )
        } catch {
            $outputTextBox.AppendText("[UPLOAD] [X] Import failed: $($_.Exception.Message)`n")
            [System.Windows.Forms.MessageBox]::Show(
                "Import failed: $($_.Exception.Message)",
                'Import Error',
                'OK',
                'Error'
            )
        }
    })
    $ruleGroupBox.Controls.Add($uploadButton)

    # Options group (moved down)
    $optionsGroupBox = New-Object System.Windows.Forms.GroupBox
    $optionsGroupBox.Location = New-Object System.Drawing.Point(20, 350)
    $optionsGroupBox.Size = New-Object System.Drawing.Size(660, 80)
    $optionsGroupBox.Text = 'Options'
    $optionsGroupBox.ForeColor = $textColor
    $optionsGroupBox.BackColor = $bgMedium
    $optionsGroupBox.FlatStyle = 'Flat'
    $form.Controls.Add($optionsGroupBox)

    # Sync mode checkbox
    $syncCheckBox = New-Object System.Windows.Forms.CheckBox
    $syncCheckBox.Location = New-Object System.Drawing.Point(10, 25)
    $syncCheckBox.Size = New-Object System.Drawing.Size(600, 20)
    $syncCheckBox.Text = 'Sync Mode (Remove entries not in the file)'
    $syncCheckBox.Checked = $false
    $syncCheckBox.ForeColor = $textColor
    $syncCheckBox.BackColor = $bgDark
    $optionsGroupBox.Controls.Add($syncCheckBox)

    # Info label for sync mode
    $syncInfoLabel = New-Object System.Windows.Forms.Label
    $syncInfoLabel.Location = New-Object System.Drawing.Point(30, 45)
    $syncInfoLabel.Size = New-Object System.Drawing.Size(590, 25)
    $syncInfoLabel.Text = 'Warning: This will remove any blocked senders/domains not present in your text file.'
    $syncInfoLabel.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $syncInfoLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
    $syncInfoLabel.BackColor = $bgDark
    $optionsGroupBox.Controls.Add($syncInfoLabel)

    # Progress group (moved down)
    $progressGroupBox = New-Object System.Windows.Forms.GroupBox
    $progressGroupBox.Location = New-Object System.Drawing.Point(20, 440)
    $progressGroupBox.Size = New-Object System.Drawing.Size(660, 200)
    $progressGroupBox.Text = 'Progress'
    $progressGroupBox.ForeColor = $textColor
    $progressGroupBox.BackColor = $bgMedium
    $progressGroupBox.FlatStyle = 'Flat'
    $form.Controls.Add($progressGroupBox)

    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10, 25)
    $progressBar.Size = New-Object System.Drawing.Size(610, 23)
    $progressBar.Style = 'Continuous'
    $progressGroupBox.Controls.Add($progressBar)

    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(10, 25)
    $statusLabel.Size = New-Object System.Drawing.Size(610, 20)
    $statusLabel.Text = 'Ready to start...'
    $statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $statusLabel.ForeColor = $textGray
    $statusLabel.BackColor = $bgDark
    $progressGroupBox.Controls.Add($statusLabel)

    # Connection status indicator (top-right corner)
    $connectionLabel = New-Object System.Windows.Forms.Label
    $connectionLabel.Location = New-Object System.Drawing.Point(520, 15)
    $connectionLabel.Size = New-Object System.Drawing.Size(60, 20)
    $connectionLabel.Text = '●'
    $connectionLabel.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $connectionLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
    $connectionLabel.BackColor = $bgDark
    $connectionLabel.TextAlign = 'MiddleCenter'
    $form.Controls.Add($connectionLabel)

    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10, 65)
    $progressBar.Size = New-Object System.Drawing.Size(610, 23)
    $progressBar.Style = 'Continuous'
    $progressGroupBox.Controls.Add($progressBar)

    # Output textbox
    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 95)
    $outputTextBox.Size = New-Object System.Drawing.Size(640, 95)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = 'Vertical'
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font('Consolas', 9)
    $outputTextBox.BackColor = $bgMedium
    $outputTextBox.ForeColor = $textColor
    $outputTextBox.BorderStyle = 'FixedSingle'
    $progressGroupBox.Controls.Add($outputTextBox)

    # Start button
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Location = New-Object System.Drawing.Point(450, 660)
    $startButton.Size = New-Object System.Drawing.Size(100, 30)
    $startButton.Text = 'Start'
    $startButton.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $startButton.BackColor = $accentBlue
    $startButton.ForeColor = [System.Drawing.Color]::White
    $startButton.FlatStyle = 'Flat'
    $startButton.FlatAppearance.BorderSize = 0
    $startButton.Enabled = $false
    $startButton.Add_Click({
        # Validate file path
        if (-not (Test-Path -LiteralPath $fileTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                "File not found: $($fileTextBox.Text)`n`nPlease select a valid file.",
                'File Not Found',
                'OK',
                'Error'
            )
            return
        }

        # Disable controls during execution
        $startButton.Enabled = $false
        $closeButton.Enabled = $false
        $browseButton.Enabled = $false
        $fileTextBox.ReadOnly = $true
        $syncCheckBox.Enabled = $false

        $outputTextBox.Clear()
        $progressBar.Value = 0
        $statusLabel.Text = 'Initializing...'
        $connectionLabel.Text = 'Connecting to Exchange Online...'
        $connectionLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 165, 0)

        # Prepare parameters
        $scriptPath = Join-Path $PSScriptRoot 'Main-Controller.ps1'
        $params = @{
            BlockedTxtPath = $fileTextBox.Text
        }

        if ($syncCheckBox.Checked) {
            $params['RemoveMissing'] = $true
        }

        # Run script in background job
        $job = Start-Job -ScriptBlock {
            param($ScriptPath, $Params)
            & $ScriptPath @Params
        } -ArgumentList $scriptPath, $params

        # Monitor job progress
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 500
        $timer.Add_Tick({
            # Get any new output while running
            if ($job.HasMoreData) {
                $newOutput = Receive-Job -Job $job
                if ($newOutput) {
                    $outputText = ($newOutput | Out-String)
                    $outputTextBox.AppendText($outputText)

                    # Update connection status based on output
                    if ($outputText -match 'Connected successfully') {
                        $connectionLabel.Text = '[OK] Connected to Exchange Online'
                        $connectionLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 0)
                    } elseif ($outputText -match 'Using existing') {
                        $connectionLabel.Text = '[OK] Using existing Exchange Online connection'
                        $connectionLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 0)
                    }
                }
            }

            # Check if job is still running
            if ($job.State -eq 'Running') {
                # Animate progress bar
                if ($progressBar.Value -lt 95) {
                    $progressBar.Value += 1
                }
                $statusLabel.Text = 'Processing... Please wait.'
            }
            elseif ($job.State -eq 'Completed') {
                $timer.Stop()
                $progressBar.Value = 100
                $statusLabel.Text = 'Completed successfully!'
                $connectionLabel.Text = '[OK] Task completed'
                $connectionLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 0)

                Remove-Job -Job $job

                # Re-enable controls
                $startButton.Enabled = $true
                $closeButton.Enabled = $true
                $browseButton.Enabled = $true
                $fileTextBox.ReadOnly = $false
                $syncCheckBox.Enabled = $true

                [System.Windows.Forms.MessageBox]::Show(
                    'Spam filter has been updated successfully!',
                    'Success',
                    'OK',
                    'Information'
                )
            }
            elseif ($job.State -eq 'Failed') {
                $timer.Stop()
                $progressBar.Value = 0
                $statusLabel.Text = 'Failed! See details below.'
                $statusLabel.ForeColor = [System.Drawing.Color]::Red
                $connectionLabel.Text = '[X] Connection failed or operation failed'
                $connectionLabel.ForeColor = [System.Drawing.Color]::Red

                # Get job error and detailed information
                $jobErrors = @()
                foreach ($childJob in $job.ChildJobs) {
                    if ($childJob.Error) {
                        $jobErrors += $childJob.Error | Out-String
                    }
                }

                if ($jobErrors.Count -gt 0) {
                    $outputTextBox.AppendText("`n`n[ERROR DETAILS]`n" + ($jobErrors -join "`n"))
                }

                Remove-Job -Job $job -Force

                # Re-enable controls
                $startButton.Enabled = $true
                $closeButton.Enabled = $true
                $browseButton.Enabled = $true
                $fileTextBox.ReadOnly = $false
                $syncCheckBox.Enabled = $true

                [System.Windows.Forms.MessageBox]::Show(
                    "An error occurred. Please check the output for details.`n`nTroubleshooting:`n" +
                    "1. ExchangeOnlineManagement module - run: Install-Module ExchangeOnlineManagement`n" +
                    "2. Exchange Online admin rights required`n" +
                    "3. Check network connectivity`n" +
                    "4. Verify file exists and is readable`n`n" +
                    "See output window for detailed error messages.",
                    'Operation Failed',
                    'OK',
                    'Error'
                )
            }
        })
        $timer.Start()
    })
    $form.Controls.Add($startButton)

    # Close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(570, 660)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Text = 'Close'
    $closeButton.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $closeButton.BackColor = $bgLight
    $closeButton.ForeColor = $textColor
    $closeButton.FlatStyle = 'Flat'
    $closeButton.FlatAppearance.BorderColor = $textGray
    $closeButton.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($closeButton)

    # Form Load event - Initialize GUI without auto-connect
    $form.Add_Load({
        $outputTextBox.Clear()
        $outputTextBox.AppendText("Welcome to Exchange Online Spam Manager`n")
        $outputTextBox.AppendText("Checking connection status...`n")

        # Check for existing session using our improved function
        if (Test-ExchangeOnlineConnection) {
            & $script:UpdateConnectionStatusBlock
            $outputTextBox.AppendText("[INFO] Connected to Exchange Online`n")
        } else {
            & $script:UpdateConnectionStatusBlock
            $outputTextBox.AppendText("[INFO] Not connected. Please click 'Login' to connect.`n")
        }
        $outputTextBox.AppendText("`n")
    })

    # Form resize event for responsive layout
    $form.Add_Resize({
        $formWidth = $form.ClientSize.Width
        $formHeight = $form.ClientSize.Height

        # Adjust title and subtitle
        $titleLabel.Size = New-Object System.Drawing.Size(($formWidth - 40), 30)
        $subtitleLabel.Size = New-Object System.Drawing.Size(($formWidth - 40), 20)

        # Adjust group boxes
        $fileGroupBox.Size = New-Object System.Drawing.Size(($formWidth - 40), 80)
        $ruleGroupBox.Size = New-Object System.Drawing.Size(($formWidth - 40), 120)
        $optionsGroupBox.Size = New-Object System.Drawing.Size(($formWidth - 40), 80)
        $progressGroupBox.Size = New-Object System.Drawing.Size(($formWidth - 40), ($formHeight - 440))
        $progressGroupBox.Location = New-Object System.Drawing.Point(20, 440)

        # Adjust output textbox
        $outputTextBox.Size = New-Object System.Drawing.Size(($formWidth - 60), ($formHeight - 490))

        # Adjust buttons
        $startButton.Location = New-Object System.Drawing.Point(($formWidth - 150), ($formHeight - 55))
        $closeButton.Location = New-Object System.Drawing.Point(($formWidth - 100), ($formHeight - 55))
        $loginButton.Location = New-Object System.Drawing.Point(20, 180)
        $logoutButton.Location = New-Object System.Drawing.Point(130, 180)
        
        # Adjust connection indicator (top-right)
        $connectionLabel.Location = New-Object System.Drawing.Point(($formWidth - 80), 15)
    })

    # Show form
    [void]$form.ShowDialog()

    # Cleanup
    try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}
}