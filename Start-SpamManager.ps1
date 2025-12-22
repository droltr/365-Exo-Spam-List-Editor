<#
.SYNOPSIS
    GUI Launcher for Exchange Online Spam Manager

.DESCRIPTION
    Provides a user-friendly Windows Forms interface to manage Exchange Online spam filtering.
    Features a modern dark theme with intuitive controls for file selection, options, and progress monitoring.

    Features:
    - Modern dark theme interface for reduced eye strain
    - File browser for easy blocked entries file selection
    - Sync mode toggle with visual warning
    - Real-time progress bar and status updates
    - Live console output window (Consolas font)
    - Color-coded messages (warnings, success, errors)
    - Background job execution with proper error handling

.EXAMPLE
    .\Start-SpamManager.ps1
    Launches the GUI interface

.NOTES
    Version:        1.0.0
    Author:         Exchange Spam Manager Project
    Creation Date:  2025-12-22
    Purpose:        Provide GUI for Exchange Online spam management

    Requirements:
    - Windows operating system (Windows Forms)
    - PowerShell 5.1 or later
    - EXO-SpamManager.ps1 in same directory

.LINK
    https://github.com/yourusername/exchange-spam-manager
#>

[CmdletBinding()]
param()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Dark theme colors
$bgDark = [System.Drawing.Color]::FromArgb(30, 30, 30)
$bgMedium = [System.Drawing.Color]::FromArgb(45, 45, 48)
$bgLight = [System.Drawing.Color]::FromArgb(60, 60, 60)
$textColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$textGray = [System.Drawing.Color]::FromArgb(160, 160, 160)
$accentBlue = [System.Drawing.Color]::FromArgb(0, 120, 212)
$accentHover = [System.Drawing.Color]::FromArgb(0, 102, 204)

# Set up form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Exchange Online Spam Manager'
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.BackColor = $bgDark

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(640, 30)
$titleLabel.Text = 'Exchange Online Spam Filter Manager'
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $textColor
$titleLabel.BackColor = $bgDark
$form.Controls.Add($titleLabel)

# Subtitle label
$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 55)
$subtitleLabel.Size = New-Object System.Drawing.Size(640, 20)
$subtitleLabel.Text = 'Import blocked senders and domains from a text file'
$subtitleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$subtitleLabel.ForeColor = $textGray
$subtitleLabel.BackColor = $bgDark
$form.Controls.Add($subtitleLabel)

# File selection group
$fileGroupBox = New-Object System.Windows.Forms.GroupBox
$fileGroupBox.Location = New-Object System.Drawing.Point(20, 90)
$fileGroupBox.Size = New-Object System.Drawing.Size(640, 80)
$fileGroupBox.Text = 'File Selection'
$fileGroupBox.ForeColor = $textColor
$fileGroupBox.BackColor = $bgDark
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

# Options group
$optionsGroupBox = New-Object System.Windows.Forms.GroupBox
$optionsGroupBox.Location = New-Object System.Drawing.Point(20, 180)
$optionsGroupBox.Size = New-Object System.Drawing.Size(640, 80)
$optionsGroupBox.Text = 'Options'
$optionsGroupBox.ForeColor = $textColor
$optionsGroupBox.BackColor = $bgDark
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

# Progress group
$progressGroupBox = New-Object System.Windows.Forms.GroupBox
$progressGroupBox.Location = New-Object System.Drawing.Point(20, 270)
$progressGroupBox.Size = New-Object System.Drawing.Size(640, 230)
$progressGroupBox.Text = 'Progress'
$progressGroupBox.ForeColor = $textColor
$progressGroupBox.BackColor = $bgDark
$form.Controls.Add($progressGroupBox)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 25)
$progressBar.Size = New-Object System.Drawing.Size(610, 23)
$progressBar.Style = 'Continuous'
$progressGroupBox.Controls.Add($progressBar)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 55)
$statusLabel.Size = New-Object System.Drawing.Size(610, 20)
$statusLabel.Text = 'Ready to start...'
$statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$statusLabel.ForeColor = $textGray
$statusLabel.BackColor = $bgDark
$progressGroupBox.Controls.Add($statusLabel)

# Output textbox
$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10, 80)
$outputTextBox.Size = New-Object System.Drawing.Size(610, 135)
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
$startButton.Location = New-Object System.Drawing.Point(450, 515)
$startButton.Size = New-Object System.Drawing.Size(100, 30)
$startButton.Text = 'Start'
$startButton.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$startButton.BackColor = $accentBlue
$startButton.ForeColor = [System.Drawing.Color]::White
$startButton.FlatStyle = 'Flat'
$startButton.FlatAppearance.BorderSize = 0
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
    $statusLabel.Text = 'Starting...'

    # Prepare parameters
    $scriptPath = Join-Path $PSScriptRoot 'EXO-SpamManager.ps1'
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

            # Get job output
            $output = Receive-Job -Job $job
            $outputTextBox.Text = ($output | Out-String)

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

            # Get job error
            $output = Receive-Job -Job $job -ErrorAction SilentlyContinue
            $error = $job.ChildJobs[0].Error | Out-String
            $outputTextBox.Text = ($output | Out-String) + "`n`nERRORS:`n" + $error

            Remove-Job -Job $job -Force

            # Re-enable controls
            $startButton.Enabled = $true
            $closeButton.Enabled = $true
            $browseButton.Enabled = $true
            $fileTextBox.ReadOnly = $false
            $syncCheckBox.Enabled = $true

            [System.Windows.Forms.MessageBox]::Show(
                "An error occurred. Please check the output for details.`n`nCommon issues:`n- Exchange Online module not installed`n- Insufficient permissions`n- Network connectivity",
                'Error',
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
$closeButton.Location = New-Object System.Drawing.Point(560, 515)
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

# Show form
[void]$form.ShowDialog()
