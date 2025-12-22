# Contributing to Exchange Online Spam Manager

Thank you for considering contributing to this project! This document provides guidelines for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Submitting Changes](#submitting-changes)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Publishing others' private information
- Other unprofessional conduct

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report:

1. **Check existing issues** - The bug might already be reported
2. **Test with latest version** - Ensure you're using the latest release
3. **Gather information** - Collect error messages, logs, and reproduction steps

Create a detailed bug report including:

```markdown
**Description**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected Behavior**
What you expected to happen

**Actual Behavior**
What actually happened

**Environment**
- OS: [e.g., Windows 11]
- PowerShell Version: [e.g., 7.3.0]
- Module Version: [e.g., ExchangeOnlineManagement 3.0.0]

**Screenshots/Logs**
If applicable, add screenshots or error logs

**Additional Context**
Any other relevant information
```

### Suggesting Features

Feature requests are welcome! Please:

1. **Check existing requests** - Avoid duplicates
2. **Describe the problem** - What problem does this solve?
3. **Describe the solution** - How should it work?
4. **Consider alternatives** - Are there other ways to achieve this?

Use this template:

```markdown
**Feature Description**
Clear description of the feature

**Problem Statement**
What problem does this solve?

**Proposed Solution**
How should it work?

**Alternatives Considered**
Other approaches you've considered

**Additional Context**
Screenshots, mockups, or examples
```

### Improving Documentation

Documentation improvements are always welcome:

- Fix typos or unclear wording
- Add examples or clarifications
- Improve formatting
- Translate documentation
- Add FAQ entries

## Development Setup

### Prerequisites

1. **PowerShell**: Version 5.1 or later
2. **Git**: For version control
3. **Exchange Online Module**:
   ```powershell
   Install-Module -Name ExchangeOnlineManagement
   ```
4. **Code Editor**: VS Code recommended with PowerShell extension

### Getting Started

1. **Fork the repository**

2. **Clone your fork**:
   ```powershell
   git clone https://github.com/YOUR_USERNAME/exchange-spam-manager.git
   cd exchange-spam-manager
   ```

3. **Create a branch**:
   ```powershell
   git checkout -b feature/your-feature-name
   ```

4. **Make changes** following coding standards

5. **Test your changes** thoroughly

6. **Commit with clear messages**:
   ```powershell
   git add .
   git commit -m "Add feature: description of what you added"
   ```

7. **Push to your fork**:
   ```powershell
   git push origin feature/your-feature-name
   ```

8. **Create a Pull Request**

## Coding Standards

### PowerShell Style Guide

#### Naming Conventions

- **Functions**: Use approved verbs (Get, Set, New, Remove, etc.)
  ```powershell
  # Good
  function Get-SpamEntries { }

  # Bad
  function Fetch-SpamEntries { }
  ```

- **Variables**: Use clear, descriptive names with camelCase
  ```powershell
  # Good
  $blockedEmails = @()

  # Bad
  $be = @()
  ```

- **Parameters**: Use PascalCase
  ```powershell
  param(
      [string]$BlockedTxtPath,
      [string]$PolicyName
  )
  ```

#### Code Structure

- **Use approved verbs**: Get, Set, New, Remove, Test, etc.
- **Comment complex logic**: Explain why, not what
- **Keep functions focused**: One responsibility per function
- **Use proper error handling**: Try/catch blocks with meaningful messages

#### Formatting

- **Indentation**: 2 or 4 spaces (be consistent)
- **Line length**: Max 120 characters
- **Braces**: Opening brace on same line
  ```powershell
  if ($condition) {
      # code
  }
  ```

#### Comments

Use comments for:
- Function documentation
- Complex algorithms
- Non-obvious decisions
- TODO items

```powershell
<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.PARAMETER ParameterName
    Parameter description
.EXAMPLE
    Example usage
#>
function Verb-Noun {
    param()

    # Single line comment for logic explanation

    # TODO: Future improvement
}
```

### Code Language Requirements

**CRITICAL**: All code must be written in English:

- ✅ Function names in English
- ✅ Variable names in English
- ✅ Comments in English
- ✅ Error messages in English
- ✅ Documentation in English

```powershell
# Good - All English
function Get-BlockedSenders {
    param([string]$Path)

    # Read file and parse entries
    $entries = Get-Content $Path
    return $entries
}

# Bad - Mixed languages
function Al-EngelliGonderenler {
    param([string]$Yol)

    # Dosyayı oku ve parse et
    $girdiler = Get-Content $Yol
    return $girdiler
}
```

**Note**: User-facing messages (GUI labels, CLI output) are currently in Turkish for the target audience but should be made localizable in future versions.

### Testing

Before submitting:

1. **Test all scenarios**:
   - GUI mode
   - CLI mode
   - Incremental mode
   - Sync mode
   - Error conditions

2. **Test with different files**:
   - Empty file
   - Large file (1000+ entries)
   - Invalid entries
   - Comments only

3. **Test error handling**:
   - Missing file
   - Invalid permissions
   - Network issues
   - Module not installed

4. **Verify no regressions**:
   - Existing features still work
   - No new errors introduced

### Documentation

Update documentation when:

- Adding new features
- Changing existing behavior
- Fixing bugs that affect usage
- Adding new parameters

Update these files as needed:
- README.md
- USAGE.md
- FAQ.md
- INSTALL.md

## Submitting Changes

### Pull Request Process

1. **Ensure all tests pass**
2. **Update documentation**
3. **Follow commit message guidelines**
4. **Create detailed PR description**

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
How was this tested?

## Checklist
- [ ] Code follows style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] All tests pass
- [ ] No new warnings

## Related Issues
Closes #issue_number
```

### Commit Message Guidelines

Use clear, descriptive commit messages:

```
Format: <type>: <subject>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Formatting changes
- refactor: Code restructuring
- test: Test additions/changes
- chore: Maintenance tasks

Examples:
feat: Add IP address blocking support
fix: Resolve authentication timeout issue
docs: Update installation guide for PowerShell 7
style: Format code according to style guide
refactor: Simplify file parsing logic
test: Add tests for domain validation
chore: Update dependencies
```

## Development Workflow

### Branch Naming

Use descriptive branch names:

```
feature/add-ip-blocking
bugfix/authentication-timeout
docs/improve-readme
refactor/simplify-parser
```

### Review Process

1. **Automated checks**: Ensure all pass
2. **Code review**: Wait for maintainer review
3. **Address feedback**: Make requested changes
4. **Approval**: Maintainer approves PR
5. **Merge**: Maintainer merges to main

## Feature Development Guidelines

### Adding New Features

1. **Discuss first**: Open an issue to discuss the feature
2. **Design**: Plan the implementation
3. **Implement**: Write code following standards
4. **Test**: Thoroughly test the feature
5. **Document**: Update all relevant documentation
6. **Submit**: Create PR with detailed description

### Example: Adding IP Blocking

```powershell
# 1. Add parameter
param(
    [string[]]$BlockedIPs
)

# 2. Create classification function
function Get-IPAddresses {
    param([string[]]$Lines)
    # Implementation
}

# 3. Add policy update logic
function Update-IPBlockList {
    param([string[]]$IPs)
    # Implementation
}

# 4. Update main workflow
# 5. Add tests
# 6. Update documentation
```

## Code Review Checklist

For reviewers:

- [ ] Code follows style guidelines
- [ ] Changes are necessary and minimal
- [ ] No hardcoded secrets or credentials
- [ ] Error handling is appropriate
- [ ] Comments explain complex logic
- [ ] Documentation is updated
- [ ] No breaking changes (or properly documented)
- [ ] Performance considerations addressed
- [ ] Security implications considered

## Getting Help

Need help contributing?

- **Questions**: Open a discussion on GitHub
- **Issues**: Comment on related issues
- **Chat**: Contact maintainers

## Recognition

Contributors will be:

- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in relevant documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing!** Your efforts help make this tool better for everyone.
