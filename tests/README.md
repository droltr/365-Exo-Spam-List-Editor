# Tests

This directory contains test scripts for the Exchange Online Spam Manager.

## Test Files

### Test-Parser.ps1
Tests the file parsing and classification logic.

### Test-BrowserDetection.ps1
Tests the default browser detection from Windows registry.

**Usage:**
```powershell
.\tests\Test-Parser.ps1
```

**What it tests:**
- Email address regex matching
- Domain regex matching
- Wildcard domain conversion (*.domain.com → domain.com)
- Comment and empty line handling
- HashSet deduplication

**Expected output:**
```
[PASS] All tests passed!
```

### Test-GUI-Without-Login.ps1
Simulates the spam manager operations without requiring Exchange Online connection.

**Usage:**
```powershell
.\tests\Test-GUI-Without-Login.ps1 -BlockedTxtPath ".\blocked.example.txt"
```

**What it simulates:**
- File reading and classification
- Progress messages
- Summary output
- No actual Exchange Online connection

### test-blocked.txt
Sample test file for parser testing.

**Contents:**
- Email addresses
- Domains
- Wildcard domains
- Comments
- Empty lines

## Running All Tests

To run all tests:

```powershell
# Test parser
.\tests\Test-Parser.ps1

# Test simulation (no EXO connection needed)
.\tests\Test-GUI-Without-Login.ps1 -BlockedTxtPath ".\blocked.example.txt"

# Test GUI (visual test)
.\Start-SpamManager.ps1
```

## Adding New Tests

When adding new tests:

1. Name test files with `Test-` prefix
2. Add proper help documentation
3. Include validation and exit codes
4. Update this README

## Test Requirements

- PowerShell 5.1 or later
- No Exchange Online connection needed for unit tests
- Windows Forms required for GUI tests

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Parser Tests
  run: pwsh -File tests/Test-Parser.ps1
```

---

**Note**: Full integration tests requiring Exchange Online connection should be run manually in a test environment.
