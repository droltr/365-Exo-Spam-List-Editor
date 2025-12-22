# Project Structure

This document describes the organization of the Exchange Online Spam Manager project.

## Directory Tree

```
exchange-spam-manager/
├── .github/                    # GitHub-specific files
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md      # Bug report template
│   │   └── feature_request.md # Feature request template
│   └── pull_request_template.md # Pull request template
├── blocked.txt                 # User's blocked entries file (gitignored)
├── blocked.example.txt         # Example/template file
├── EXO-SpamManager.ps1        # Main PowerShell script (CLI mode)
├── Start-SpamManager.ps1      # GUI launcher script
├── .gitignore                 # Git ignore rules
├── LICENSE                    # MIT License
├── README.md                  # Main documentation
├── INSTALL.md                 # Installation guide
├── USAGE.md                   # Usage guide with examples
├── FAQ.md                     # Frequently Asked Questions
├── CONTRIBUTING.md            # Contribution guidelines
├── CHANGELOG.md               # Version history
└── PROJECT_STRUCTURE.md       # This file
```

## File Descriptions

### Main Scripts

#### `EXO-SpamManager.ps1`
**Purpose**: Core PowerShell script for managing Exchange Online spam filters

**Key Features**:
- CLI mode operation
- Connects to Exchange Online
- Reads and classifies entries from text file
- Updates spam filter policies
- Creates/updates inbound filter rules
- Supports incremental and sync modes

**Parameters**:
- `BlockedTxtPath`: Path to blocked entries file (default: `C:\scripts\blocked.txt`)
- `PolicyName`: Name of spam policy to update (default: `Spam`)
- `RuleName`: Name of inbound rule (default: `Spam (Inbound Rule)`)
- `RemoveMissing`: Switch for sync mode

**Usage**:
```powershell
.\EXO-SpamManager.ps1 -BlockedTxtPath ".\blocked.txt"
```

#### `Start-SpamManager.ps1`
**Purpose**: GUI launcher providing user-friendly interface

**Key Features**:
- Windows Forms interface
- File browser for easy file selection
- Sync mode checkbox
- Real-time progress bar
- Live output window
- Success/error dialogs

**Usage**:
```powershell
.\Start-SpamManager.ps1
```

### Data Files

#### `blocked.txt`
**Purpose**: User's actual blocked entries file

**Status**: Gitignored (not tracked in version control)

**Format**: Plain text, UTF-8, one entry per line

**Content Types**:
- Email addresses (e.g., `spam@example.com`)
- Domains (e.g., `malicious.org`)
- Comments (lines starting with `#` or `;`)
- IP addresses (future feature)
- Keywords (future feature)

#### `blocked.example.txt`
**Purpose**: Template/example file for users

**Status**: Tracked in Git

**Content**: Documentation and examples of supported formats

### Documentation

#### `README.md`
**Purpose**: Main project documentation

**Sections**:
- Overview and features
- Prerequisites
- Installation
- Quick start (GUI and CLI)
- File format
- How it works
- Parameters
- Security notes
- Troubleshooting
- Roadmap

**Audience**: All users

#### `INSTALL.md`
**Purpose**: Detailed installation instructions

**Sections**:
- System requirements
- Step-by-step installation
- One-time Exchange Online setup
- Testing
- Troubleshooting installation issues
- Upgrade instructions
- Uninstallation

**Audience**: New users, system administrators

#### `USAGE.md`
**Purpose**: Comprehensive usage guide

**Sections**:
- GUI mode walkthrough
- CLI mode examples
- File format details
- Common scenarios
- Best practices
- Advanced usage
- Integration examples

**Audience**: Active users, power users

#### `FAQ.md`
**Purpose**: Frequently asked questions and answers

**Sections**:
- General questions
- Installation & setup
- Usage questions
- File format
- Authentication
- Error messages
- Performance
- Advanced topics
- Troubleshooting workflow

**Audience**: All users encountering issues

#### `CONTRIBUTING.md`
**Purpose**: Guidelines for contributors

**Sections**:
- Code of conduct
- How to contribute
- Development setup
- Coding standards
- Submitting changes
- Bug reporting
- Feature requests
- Code review checklist

**Audience**: Developers, contributors

#### `CHANGELOG.md`
**Purpose**: Version history and release notes

**Format**: Keep a Changelog format

**Content**:
- Version numbers (Semantic Versioning)
- Release dates
- Added/Changed/Deprecated/Removed/Fixed/Security sections

**Audience**: All users, especially those upgrading

#### `PROJECT_STRUCTURE.md`
**Purpose**: This document - explains project organization

**Audience**: Developers, contributors

### Configuration Files

#### `.gitignore`
**Purpose**: Specifies files Git should ignore

**Ignored Items**:
- `blocked.txt` (user data)
- Log files (`*.log`, `logs/`)
- Backup files (`*.bak`, `*.backup`)
- IDE settings (`.vscode/`, `.idea/`)
- Test files (`test_*.txt`)

#### `LICENSE`
**Purpose**: MIT License terms

**Key Points**:
- Free to use, modify, distribute
- Provided "as is" without warranty
- Must include license in distributions

### GitHub Files

#### `.github/ISSUE_TEMPLATE/bug_report.md`
**Purpose**: Template for bug reports

**Guides users to provide**:
- Bug description
- Reproduction steps
- Expected vs actual behavior
- Environment details
- Error logs

#### `.github/ISSUE_TEMPLATE/feature_request.md`
**Purpose**: Template for feature requests

**Guides users to provide**:
- Feature description
- Problem statement
- Proposed solution
- Alternatives considered
- Use cases

#### `.github/pull_request_template.md`
**Purpose**: Template for pull requests

**Ensures PRs include**:
- Description of changes
- Type of change
- Testing performed
- Checklist compliance
- Breaking changes (if any)

## Code Architecture

### EXO-SpamManager.ps1 Functions

| Function | Purpose |
|----------|---------|
| `Write-Info` | Timestamped console logging |
| `Ensure-Module` | Load PowerShell modules with error suppression |
| `Get-NewTabBrowser` | Find installed browser for authentication |
| `Connect-EXO` | Establish Exchange Online connection |
| `Read-Lines` | Read text file with UTF-8 encoding |
| `Classify` | Parse and classify entries (emails/domains) |
| `Ensure-PolicyExists` | Verify spam policy exists |
| `Ensure-RuleForAllAcceptedDomains` | Create/update inbound rule |
| `Update-BlockedLists` | Add/remove entries from policy |

### Start-SpamManager.ps1 Components

| Component | Type | Purpose |
|-----------|------|---------|
| Form | Window | Main window container |
| Title/Subtitle Labels | Label | Header information |
| File GroupBox | GroupBox | File selection section |
| File TextBox | TextBox | Display selected file path |
| Browse Button | Button | Open file browser dialog |
| Options GroupBox | GroupBox | Configuration options |
| Sync CheckBox | CheckBox | Toggle sync mode |
| Progress GroupBox | GroupBox | Progress display section |
| Progress Bar | ProgressBar | Visual progress indicator |
| Status Label | Label | Current operation status |
| Output TextBox | TextBox | Console output display |
| Start Button | Button | Execute operation |
| Close Button | Button | Close application |

## Data Flow

### GUI Mode Flow

```
User → Start-SpamManager.ps1
  ↓
User selects file & options
  ↓
Click "Start"
  ↓
Start background job running EXO-SpamManager.ps1
  ↓
Timer monitors job progress
  ↓
Display output in real-time
  ↓
Show completion dialog
  ↓
Re-enable controls
```

### CLI Mode Flow

```
User → EXO-SpamManager.ps1
  ↓
Connect to Exchange Online
  ↓
Read blocked.txt
  ↓
Classify entries (emails/domains)
  ↓
Verify policy exists
  ↓
Update policy blocked lists
  ↓
Create/update inbound rule
  ↓
Display summary
  ↓
Disconnect from Exchange Online
```

### Entry Classification Logic

```
Read line from file
  ↓
Trim whitespace
  ↓
Skip if empty or comment (# or ;)
  ↓
Match against email regex → Add to emails list
  ↓
Match against domain regex → Process wildcards → Add to domains list
  ↓
No match → Skip with warning (future: IP/keyword processing)
```

## Dependencies

### PowerShell Modules

- `ExchangeOnlineManagement`: Official Microsoft module for Exchange Online management
  - Version: 2.0.5 or later recommended
  - Source: PowerShell Gallery

### .NET Assemblies (GUI only)

- `System.Windows.Forms`: Windows Forms UI framework
- `System.Drawing`: Drawing and graphics support

### External Requirements

- Windows Operating System (GUI mode)
- PowerShell 5.1+ or PowerShell 7+
- Internet connectivity
- Exchange Online subscription
- Administrator permissions in Exchange Online

## Naming Conventions

### Files
- Scripts: PascalCase with verb-noun pattern (`Start-SpamManager.ps1`)
- Documentation: UPPERCASE for main docs (`README.md`), PascalCase for others
- Templates: `.example` suffix for template files

### Code
- Functions: Verb-Noun pattern (`Get-NewTabBrowser`)
- Variables: camelCase (`$blockedEmails`)
- Parameters: PascalCase (`$BlockedTxtPath`)
- Constants: UPPER_CASE (if any)

### Git
- Branches: `feature/`, `bugfix/`, `docs/`, etc.
- Commits: `type: description` (e.g., `feat: add IP blocking`)
- Tags: `v1.0.0` (Semantic Versioning)

## Future Structure Plans

### Planned Additions

```
exchange-spam-manager/
├── src/                       # Source code folder
│   ├── core/
│   │   ├── Parser.ps1        # Entry parsing logic
│   │   └── PolicyManager.ps1 # Policy management
│   └── gui/
│       └── MainWindow.ps1    # GUI components
├── tests/                     # Unit and integration tests
│   ├── Parser.Tests.ps1
│   └── PolicyManager.Tests.ps1
├── locales/                   # Localization files
│   ├── en-US.psd1
│   └── tr-TR.psd1
├── examples/                  # Example configurations
│   ├── multi-policy.ps1
│   └── automation.ps1
└── docs/                      # Additional documentation
    └── screenshots/
```

### Planned Features Impact

- **IP Blocking**: Add IP parser in `Classify` function, new Transport Rule management
- **Keywords**: Add keyword parser, new Transport Rule creation for content filtering
- **Export**: New function to dump current policy to file
- **Localization**: Separate UI strings into locale files
- **Tests**: Add Pester test framework for automated testing

## Maintenance Guidelines

### Regular Updates

- Update `CHANGELOG.md` for every release
- Review and update FAQ based on user issues
- Keep dependencies updated
- Review and merge security patches promptly

### Version Numbering

Follow Semantic Versioning (SemVer):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

Example: `1.2.3`
- `1` = Major version
- `2` = Minor version (new features)
- `3` = Patch version (bug fixes)

---

**Last Updated**: 2025-12-22
**Version**: 1.0.0
