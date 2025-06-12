# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EiKana is a macOS native application built with SwiftUI that enables keyboard-based input method switching between English (英数) and Japanese Kana (かな) modes. Users can switch input modes by pressing modifier keys (Control or Command) without any key combinations.

## Development Commands

### Building the Project
```bash
# Build using xcodebuild (default scheme)
xcodebuild clean build -scheme EiKana -project EiKana.xcodeproj

# Build with analysis
xcodebuild clean build analyze -scheme EiKana -project EiKana.xcodeproj
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -scheme EiKana -project EiKana.xcodeproj -destination 'platform=macOS'

# Run specific test
xcodebuild test -scheme EiKana -project EiKana.xcodeproj -destination 'platform=macOS' -only-testing:EiKanaTests/TestClassName
```

### Linting/Formatting
The project uses a git pre-commit hook to remove trailing whitespace from Swift files. There is no additional linting setup.

## Architecture

### Core Components

1. **EiKanaApp.swift**: Main app entry point, manages status bar icon, window lifecycle, and SwiftData persistence
2. **IMEManager.swift**: Core keyboard event handling using Carbon framework's CGEventTap API
3. **ContentView.swift**: Simple UI for modifier key selection

### Key Technical Details

- Uses Carbon framework for low-level keyboard event monitoring
- Implements CGEventTap to intercept modifier key events
- Distinguishes between modifier usage and standalone key presses using a 0.2-second long-press threshold
- Simulates Eisu (keycode 102) and Kana (keycode 104) key presses
- Runs as accessory app (no dock icon) with auto-hiding menu bar icon

### Permissions

The app requires Accessibility permissions to monitor keyboard events. Current entitlements include:
- `com.apple.security.app-sandbox`
- `com.apple.security.files.user-selected.read-only`

## Important Notes

- The app intercepts system-level keyboard events, requiring careful handling to avoid interfering with normal keyboard usage
- Modifier key detection logic in IMEManager is critical - it must differentiate between modifier usage and standalone presses
- The app uses modern Swift features including SwiftData, @AppStorage, and Swift Testing framework
- No external dependencies - uses only native macOS frameworks