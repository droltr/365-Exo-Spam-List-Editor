# Screenshots

Visual guide to Exchange Online Spam Manager interface.

## GUI Mode - Main Window

The main interface features a modern dark theme with clear sections for file selection, options, and progress monitoring.

### Main Interface
- **Title**: Exchange Online Spam Filter Manager
- **Subtitle**: Import blocked senders and domains from a text file
- **Theme**: Dark mode with professional color scheme

### Sections

#### 1. File Selection
- Text field showing the path to blocked entries file
- Browse button to open file dialog
- Default path: `.\blocked.txt`

#### 2. Options
- Sync Mode checkbox
- Warning message about sync mode behavior
- Orange warning text for visibility

#### 3. Progress
- Progress bar showing operation status
- Status label with current operation
- Output console with real-time logs (Consolas font)
- Dark background for reduced eye strain

#### 4. Action Buttons
- **Start Button**: Blue accent color, prominent placement
- **Close Button**: Gray color, secondary action

## Color Scheme

### Dark Theme
```
Background (Dark):    #1E1E1E (30, 30, 30)
Background (Medium):  #2D2D30 (45, 45, 48)
Background (Light):   #3C3C3C (60, 60, 60)
Text (Primary):       #F0F0F0 (240, 240, 240)
Text (Secondary):     #A0A0A0 (160, 160, 160)
Accent (Blue):        #0078D4 (0, 120, 212)
Warning (Orange):     #FFA500 (255, 165, 0)
```

## UI Elements

### Buttons
- Flat style with minimal borders
- Hover effects
- Consistent padding and sizing

### Text Fields
- Dark background with light text
- Fixed single border style
- Clear contrast for readability

### Group Boxes
- Labeled sections
- Consistent spacing
- Dark theme throughout

## Screenshots Placeholder

To add actual screenshots:

1. Run the application:
   ```powershell
   .\Start-SpamManager.ps1
   ```

2. Take screenshots of:
   - Main window (initial state)
   - File browser dialog
   - Progress during operation
   - Success message
   - Error message example

3. Save screenshots in `docs/screenshots/` folder:
   - `main-window.png`
   - `file-browser.png`
   - `progress.png`
   - `success.png`
   - `error.png`

4. Update README.md with screenshot references:
   ```markdown
   ![Main Window](docs/screenshots/main-window.png)
   ```

## Future Screenshots

Once the application is in use, add:
- Exchange Online login page
- Browser authentication flow
- Results summary
- Different themes (if added)
- Mobile/responsive views (if applicable)

---

**Note**: This is a desktop Windows application using Windows Forms. Screenshots should be taken on Windows 10/11 with standard DPI settings for consistency.
