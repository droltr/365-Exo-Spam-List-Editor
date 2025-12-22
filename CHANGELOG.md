# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned Features
- IP address blocking support
- Keyword-based filtering via Transport Rules
- Export current blocked lists functionality
- Email notification on completion
- Scheduled task creation wizard
- Localization support

## [1.0.0] - 2025-12-22

### Added
- Initial release
- Windows Forms GUI for user-friendly operation
- CLI mode for automation and scripting
- Automatic classification of email addresses and domains
- Incremental update mode (default)
- Sync mode with `-RemoveMissing` parameter
- Real-time progress display in GUI
- Detailed logging with timestamps
- Browser-based OAuth authentication
- Automatic scope to all accepted domains
- Support for wildcard domains (converted to root domain)
- Comment support in blocked entries file (# and ;)
- Comprehensive documentation (README, INSTALL, USAGE, FAQ, CONTRIBUTING)
- MIT License
- GitHub issue templates
- Example blocked.txt template

### Features

#### GUI Mode
- Modern dark theme interface (professional look, reduced eye strain)
- File browser for easy file selection
- Sync mode toggle checkbox
- Real-time progress bar
- Live output window with console logs (Consolas font)
- Success/error message dialogs
- Color-coded messages (orange warnings, green success, red errors)
- Flat UI design with consistent spacing

#### CLI Mode
- Customizable policy and rule names
- Flexible file path specification
- PowerShell pipeline support
- Detailed console output
- Error handling with troubleshooting hints

#### Core Functionality
- Email address blocking (BlockedSenders list)
- Domain blocking (BlockedSenderDomains list)
- Wildcard domain support (*.example.com → example.com)
- Case-insensitive matching
- Duplicate detection and removal
- UTF-8 file encoding support
- Default browser detection for authentication (Edge, Chrome, Firefox, Brave)
- Automatic browser selection from Windows registry

#### Documentation
- Comprehensive README with quick start guide
- Detailed installation instructions (INSTALL.md)
- Extensive usage guide with examples (USAGE.md)
- FAQ covering common questions and issues
- Contributing guidelines (CONTRIBUTING.md)
- GitHub templates for issues and PRs

### Security
- OAuth-based authentication (no password storage)
- TLS encryption for all connections
- Permission verification
- Input validation and sanitization
- Secure browser integration for authentication

### Known Limitations
- IP address blocking not yet implemented
- Keywords filtering not yet implemented
- Windows-only (GUI requires Windows Forms)
- Requires Exchange Online (not on-premises Exchange)
- Limited to 1,024 entries per list (Exchange Online limitation)

## Version History Format

### Added
- New features or functionality

### Changed
- Changes to existing functionality

### Deprecated
- Features that will be removed in future versions

### Removed
- Features that have been removed

### Fixed
- Bug fixes

### Security
- Security-related changes or fixes

---

[Unreleased]: https://github.com/yourusername/exchange-spam-manager/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/exchange-spam-manager/releases/tag/v1.0.0
