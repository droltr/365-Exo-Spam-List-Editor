# 365 Exo Spam List Editor

![GitHub release (latest by date)](https://img.shields.io/github/v/release/droltr/365-Exo-Spam-List-Editor)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)

A powerful and user-friendly GUI tool for managing Exchange Online spam filters. Easily import blocked senders, domains,
 and keywords from text files directly into your Exchange Online Protection (EOP) policies and Transport Rules.

This project provides a PowerShell-based interface to interact with Exchange Online, allowing administrators to manage spam lists efficiently.

## Features

- **Modern GUI Interface:** Clean, dark-themed interface for easy navigation.
- **Bulk Import:** Import hundreds of blocked emails, domains, and keywords from a single text file.
- **Smart Classification:** Automatically detects and categorizes entries (Emails vs Domains vs Keywords).
- **Dual Protection:** Updates both EOP Blocked Senders/Domains and Transport Rules for maximum coverage.
- **Sync Mode:** Option to remove entries that are no longer in your source file (keep clean).
- **Export/Backup:** Download your current blocked lists to a text file.
- **Secure Authentication:** Supports Modern Authentication (OAuth) with Device Code flow.
- **Detailed Logging:** Real-time progress logs with timestamps.

## Prerequisites

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or newer
- Exchange Online Administrator permissions
- Internet connection

## Installation

1. Clone this repository:

`ash
git clone https://github.com/droltr/365-Exo-Spam-List-Editor.git
`

2. Ensure you have the ExchangeOnlineManagement module installed (the tool will attempt to install it if missing).

`powershell
Install-Module -Name ExchangeOnlineManagement
`

## Usage

Run the startup script via PowerShell:
`powershell
.\Start-365ExoSpamListEditor.ps1
`

## How to Use

1. **Login:** Click the **Login** button in the top-right corner. Follow the instructions to authenticate with Microsoft.
2. **Prepare File:** Create a text file with blocked entries or click **Create Example** to generate a template.
3. **Select File:** Click **Browse** and select your text file.
4. **Select Rules:** Choose which lists to update (EOP Senders, EOP Domains, Transport Rules).
5. **Start:** Click **Start** to begin the import process.

See [USAGE.md](USAGE.md) for a detailed user guide.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
