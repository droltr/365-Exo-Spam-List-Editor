# Global Coding Guidelines & User Requirements

## General Rules (Applied to All Projects)
1. **Language Rule**: Communicate with the user in Turkish, but all code, file names, comments, and technical explanations must be in English only. Do not use Turkish for any code, file name, or explanation. If any exist, correct them to English.
2. **Testing First**: Do not create documentation or upload changes before the code works and tests are completed.
3. **File Management**: Move unnecessary files to a `.deleted` folder instead of deleting them directly. The `.deleted` folder must not be uploaded to GitHub.
4. **Documentation**: Update markdown files (README.md, USAGE.md) only after code tests are completed and approved.
5. **GitHub Compatibility**: Ensure all markdown files are GitHub-compatible.
6. **Project Instructions**: Keep project-specific instructions in the project's `coding.md` file.

## Network Test Tool (v0.5) - 2024-12-22
GitHub: https://github.com/droltr/Network_Test_Tool

### UI/UX Refinements
- **General Style**: Modern, serious, and simple interface with pastel colors (Dark Theme).
- **Header**:
  - Remove version number ("v1.0").
  - Remove program name text (redundant with window title).
  - Status Indicator: Large round indicator with "Online" (Green) / "Offline" (Red) text.
- **Footer**:
  - Remove "2024 Network Tools" copyright text.
  - Clean layout.
- **Network Status Tab**:
  - **Card Layout**: Display adapters in card format.
  - **Sorting**: Active adapters (connected) must be at the top, inactive ones at the bottom.
  - **Refresh Rate**: Auto-refresh increased to 10 seconds to reduce load.
- **Menu**:
  - "Exit" button moved to the "File" menu.

### Troubleshooter (Automated Test)
- **Scope**:
  - **Remove Speed Test**: Speed test is excluded from the automated troubleshooting sequence.
  - **Active Adapters Only**: Report should only list active network interfaces.
- **Tests**:
  - **Ping**: Ping Gateway, DNS, and External Host (8.8.8.8) **3 times** each.
  - **Traceroute**: Target changed to `1.1.1.1`.

### Stability & Bug Fixes
- **Crash Prevention**: Global exception handler added to catch unhandled errors and prevent application closure.
- **Speed Test**:
  - Fixed `403 Forbidden` error by updating the configuration URL in `speedtest-cli` library.
  - Prevented duplicate log messages during testing.
