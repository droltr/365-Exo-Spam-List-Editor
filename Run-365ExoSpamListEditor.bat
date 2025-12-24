@echo off
REM Spam Manager Launcher
REM Launches the PowerShell script with Bypass execution policy and hidden console window

cd /d "%~dp0"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "Start-365ExoSpamListEditor.ps1"
