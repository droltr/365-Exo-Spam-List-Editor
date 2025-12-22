<#
.SYNOPSIS
    Demo script showing what the browser login flow looks like

.DESCRIPTION
    This opens a simple HTML page that simulates the Microsoft login experience
    to demonstrate what users will see when the real script runs.
#>

Write-Host "`n=== Browser Login Flow Demo ===" -ForegroundColor Cyan
Write-Host "This demonstrates what happens during real authentication`n" -ForegroundColor Yellow

# Create a demo HTML page
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Microsoft Login - Demo</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 8px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 440px;
            width: 100%;
            padding: 48px;
        }
        .logo {
            text-align: center;
            margin-bottom: 24px;
        }
        .logo svg {
            width: 108px;
            height: 24px;
        }
        h1 {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 8px;
            color: #1b1b1b;
        }
        p {
            color: #605e5c;
            margin-bottom: 24px;
            font-size: 15px;
        }
        .demo-badge {
            background: #ffeb3b;
            color: #000;
            padding: 8px 16px;
            border-radius: 4px;
            text-align: center;
            font-weight: bold;
            margin-bottom: 24px;
        }
        input {
            width: 100%;
            padding: 12px;
            border: 1px solid #8a8886;
            border-radius: 2px;
            font-size: 15px;
            margin-bottom: 16px;
            transition: border-color 0.2s;
        }
        input:focus {
            outline: none;
            border-color: #0078d4;
            border-width: 2px;
            padding: 11px;
        }
        .checkbox-container {
            display: flex;
            align-items: center;
            margin-bottom: 24px;
        }
        .checkbox-container input[type="checkbox"] {
            width: auto;
            margin-right: 8px;
            margin-bottom: 0;
        }
        .checkbox-container label {
            color: #1b1b1b;
            font-size: 15px;
        }
        button {
            width: 100%;
            padding: 12px;
            background: #0078d4;
            color: white;
            border: none;
            border-radius: 2px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
        }
        button:hover {
            background: #106ebe;
        }
        .info {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 16px;
            margin-top: 24px;
            border-radius: 4px;
        }
        .info h3 {
            color: #1976d2;
            margin-bottom: 8px;
            font-size: 16px;
        }
        .info ul {
            color: #424242;
            margin-left: 20px;
            font-size: 14px;
        }
        .info li {
            margin-bottom: 6px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">
            <svg viewBox="0 0 108 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <rect width="11" height="11" fill="#f25022"/>
                <rect x="13" width="11" height="11" fill="#7fba00"/>
                <rect y="13" width="11" height="11" fill="#00a4ef"/>
                <rect x="13" y="13" width="11" height="11" fill="#ffb900"/>
                <text x="30" y="18" font-family="Segoe UI" font-size="16" fill="#5e5e5e">Microsoft</text>
            </svg>
        </div>

        <div class="demo-badge">
            🎭 DEMO MODE - This is a simulation
        </div>

        <h1>Sign in</h1>
        <p>to continue to Exchange Online</p>

        <form onsubmit="handleLogin(event)">
            <input type="email" placeholder="Email, phone, or Skype" value="admin@contoso.com" required>
            <input type="password" placeholder="Password" value="••••••••" required>

            <div class="checkbox-container">
                <input type="checkbox" id="stay-signed-in">
                <label for="stay-signed-in">Keep me signed in</label>
            </div>

            <button type="submit">Sign in</button>
        </form>

        <div class="info">
            <h3>📱 In Real Usage:</h3>
            <ul>
                <li><strong>Firefox will open automatically</strong></li>
                <li>You'll see this login page at <code>login.microsoftonline.com</code></li>
                <li>Enter your Microsoft 365 credentials</li>
                <li>Complete MFA (if enabled)</li>
                <li>Browser closes after authentication</li>
                <li>Script continues with spam filter updates</li>
            </ul>
        </div>
    </div>

    <script>
        function handleLogin(e) {
            e.preventDefault();
            alert('✅ Demo: Authentication Successful!\n\nIn real usage:\n• Browser would close automatically\n• Script would connect to Exchange Online\n• Spam policies would be updated\n\nThis is just a demonstration.');

            // Simulate closing
            setTimeout(() => {
                document.body.innerHTML = '<div style="text-align:center;padding:50px;font-family:Segoe UI"><h1>✅ Authentication Complete</h1><p>You can close this window</p><p style="color:#666;margin-top:20px">The script is now updating your spam filters...</p></div>';
            }, 1000);
        }
    </script>
</body>
</html>
"@

# Save HTML to temp file
$tempHtml = Join-Path $env:TEMP "ms-login-demo.html"
$htmlContent | Out-File -FilePath $tempHtml -Encoding UTF8

Write-Host "Opening browser to demonstrate login flow..." -ForegroundColor Green
Write-Host "URL: $tempHtml`n" -ForegroundColor Gray

# Open in default browser
Start-Process $tempHtml

Write-Host "Demo browser window opened!" -ForegroundColor Green
Write-Host "`nWhat you're seeing:" -ForegroundColor Yellow
Write-Host "  • Microsoft-style login page" -ForegroundColor White
Write-Host "  • Email and password fields" -ForegroundColor White
Write-Host "  • 'Keep me signed in' option" -ForegroundColor White
Write-Host "  • Information about real usage" -ForegroundColor White

Write-Host "`nIn REAL usage with ExchangeOnlineManagement module:" -ForegroundColor Cyan
Write-Host "  1. Script detects your default browser (Firefox)" -ForegroundColor White
Write-Host "  2. Opens browser automatically to login.microsoftonline.com" -ForegroundColor White
Write-Host "  3. You enter your Microsoft 365 credentials" -ForegroundColor White
Write-Host "  4. MFA prompt appears (if enabled)" -ForegroundColor White
Write-Host "  5. After auth, browser closes automatically" -ForegroundColor White
Write-Host "  6. Script continues and updates spam policies" -ForegroundColor White

Write-Host "`nPress Enter to close and cleanup..." -ForegroundColor Yellow
Read-Host

# Cleanup
if (Test-Path $tempHtml) {
    Remove-Item $tempHtml -Force
}

Write-Host "Demo completed!" -ForegroundColor Green
