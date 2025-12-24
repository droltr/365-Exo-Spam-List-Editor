# Exchange Online Spam Manager

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)

A powerful and user-friendly GUI tool for managing Exchange Online spam filters. Easily import blocked senders, domains, and keywords from text files directly into your Exchange Online Protection (EOP) policies and Transport Rules.

## 🚀 Features

- **Modern GUI Interface:** Clean, dark-themed interface for easy navigation.
- **Bulk Import:** Import hundreds of blocked emails, domains, and keywords from a single text file.
- **Smart Classification:** Automatically detects and categorizes entries (Emails vs Domains vs Keywords).
- **Dual Protection:** Updates both EOP Blocked Senders/Domains and Transport Rules for maximum coverage.
- **Sync Mode:** Option to remove entries that are no longer in your source file (keep clean).
- **Export/Backup:** Download your current blocked lists to a text file.
- **Secure Authentication:** Supports Modern Authentication (OAuth) with Device Code flow.
- **Detailed Logging:** Real-time progress logs with timestamps.

## 📋 Prerequisites

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or newer
- Exchange Online Administrator permissions
- Internet connection

## 🛠️ Installation

1. Download the latest release or clone this repository.
2. Ensure you have the `ExchangeOnlineManagement` module installed (the tool will attempt to install it if missing).

```powershell
Install-Module -Name ExchangeOnlineManagement
```

## 🚀 Usage

### Method 1: Executable (Recommended)
Double-click `SpamManager.exe` to launch the application.

### Method 2: Batch Launcher
Double-click `Run-SpamManager.bat`.

### Method 3: PowerShell
Run the startup script:
```powershell
.\Start-SpamManager.ps1
```

## 📖 How to Use

1. **Login:** Click the **Login** button in the top-right corner. Follow the instructions to authenticate with Microsoft.
2. **Prepare File:** Create a text file with blocked entries or click **Create Example** to generate a template.
3. **Select File:** Click **Browse** and select your text file.
4. **Select Rules:** Choose which lists to update (EOP Senders, EOP Domains, Transport Rules).
5. **Start:** Click **Start** to begin the import process.

See [USAGE.md](USAGE.md) for a detailed user guide.

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
