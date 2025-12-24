# User Guide - Exchange Online Spam Manager

This guide provides detailed instructions on how to use the Exchange Online Spam Manager tool.

## Table of Contents
1. [Getting Started](#getting-started)
2. [Authentication](#authentication)
3. [Preparing Blocked Lists](#preparing-blocked-lists)
4. [Importing Rules](#importing-rules)
5. [Exporting Rules](#exporting-rules)
6. [Troubleshooting](#troubleshooting)

## Getting Started

Launch the application using `SpamManager.exe` or `Run-SpamManager.bat`. The main interface will appear.

## Authentication

1. Click the **Login** button in the top-right corner.
2. A code will be copied to your clipboard, and a browser window will open.
3. Paste the code into the Microsoft login page.
4. Sign in with your Exchange Online Administrator credentials.
5. Once authenticated, the status indicator will turn **Green**, and your account email will be displayed.

## Preparing Blocked Lists

You can import a text file containing mixed entries. The tool automatically classifies them.

### File Format
Create a `.txt` file with one entry per line.

```text
# Comments are ignored
spammer@bad-domain.com      <-- Email Address
phishing-site.net           <-- Domain
*.malicious.org             <-- Wildcard Domain

---keywords---              <-- Keyword Section Marker
urgent action required      <-- Keyword/Phrase
verify your password
```

**Tip:** Click the **Create Example** button in the application to generate a template file (`blocked_example.txt`).

## Importing Rules

1. **Select File:** Click **Browse** and choose your prepared text file.
2. **Choose Targets:**
   - **EOP Blocked Senders:** Adds email addresses to the Hosted Content Filter Policy.
   - **EOP Blocked Domains:** Adds domains to the Hosted Content Filter Policy.
   - **Transport Rules:** Creates/Updates a Transport Rule to block emails, domains, and keywords.
3. **Options:**
   - **Sync Mode:** If checked, entries NOT in your file will be REMOVED from Exchange Online. Use with caution!
4. **Start:** Click **Start** to begin. Monitor the **Progress** log for details.

## Exporting Rules

1. Click **Download Rules**.
2. Select a location to save the file.
3. The tool will download all currently blocked senders, domains, and keywords into a formatted text file.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Login Failed** | Ensure you have internet access and Admin permissions. Try running as Administrator. |
| **Module Error** | Run `Install-Module ExchangeOnlineManagement` in PowerShell manually. |
| **Not Connected** | If the status stays Orange, click Login again. |

For further assistance, please open an issue on GitHub.
