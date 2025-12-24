<#
.SYNOPSIS
    Common Utility Functions

.DESCRIPTION
    Contains shared utility functions used across multiple modules.
#>

function Write-Info {
    param([string]$Message)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "[$ts] $Message"
}

function Write-ProgressLog {
    param([string]$Message)
    Write-Host "[PROGRESS] $Message"
}
