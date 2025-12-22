@echo off
echo ========================================
echo Exchange Online Spam Manager - REAL TEST
echo ========================================
echo.
echo This will:
echo 1. Connect to Exchange Online (Firefox will open)
echo 2. You must login with your Microsoft 365 account
echo 3. Update the spam filter policy
echo.
echo Press Ctrl+C to cancel, or
pause

powershell.exe -ExecutionPolicy Bypass -File "EXO-SpamManager.ps1" -BlockedTxtPath "blocked.txt"

echo.
echo ========================================
echo Test completed!
echo ========================================
pause
