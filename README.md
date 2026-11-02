# Trimbox

A native, zero-friction clipboard manager for macOS built in Swift.

### The Problem
Traditional clipboard managers (like Maccy, Raycast, or Alfred) require you to open a UI window, browse a list, and hit Enter **every single time** you just want what you copied right before the current item.

### The Trimbox Solution
Trimbox runs silently in the background and gives you **zero-UI instant pastings**:
- **`Cmd + H` (`⌘H`)**: **Show Clipboard History Menu** — pops up your history list right at your cursor. Press `1`–`9` or click an item to paste it immediately!
- **`Option + Cmd + H` (`⌥⌘H`) / `Shift + Cmd + H` (`⇧⌘H`)**: Alternative shortcuts to show the history menu.
- **`Cmd + V`**: Pastes current copy (standard macOS behavior).
- **`Option + Cmd + V` (`⌥⌘V`)**: **Instant Pastes Previous** — pastes the item you copied right before the current one directly into your document without opening any window or UI.
- **`Option + Shift + Cmd + V` (`⌥⇧⌘V`)**: **Instant Pastes 2nd Previous** item.
- **`Option + Cmd + C` (`⌥⌘C`)**: Cycles clipboard history (swaps previous into current slot).
- **`Option + Cmd + Q` (`⌥⌘Q`)**: Toggles **FIFO Queue Mode** (Copy-Copy-Copy -> Paste-Paste-Paste in exact order).

---

## Installation & Auto-Start

Run once to build and install as a background service that auto-starts on login:

```bash
./install.sh
```

Trimbox will:
1. Compile into a native macOS `.app` bundle with zero dependencies.
2. Install to `~/Applications/Trimbox.app`.
3. Register with `launchd` (`~/Library/LaunchAgents/com.trimbox.app.plist`) so it is **always running** and starts automatically when you boot your Mac.

---

## Features

- **Zero Windows Needed**: Instant pastings at your cursor with global Carbon hotkeys.
- **Micro-HUD Feedback**: Subtle dark-glass pill appears for 1 second near bottom-center confirming what was pasted (`📋 PREVIOUS: "..."`).
- **Menu Bar Icon (`📋`)**: Live preview of your recent history, shortcuts guide, toggle HUD, and clear history.
- **Memory Efficient**: Pure AppKit/Carbon native binary (~118 KB), < 0.1% CPU usage.
- **Persistent**: Survives system reboots (persisted in `~/.trimbox/history.json`).

---

## Uninstallation

To remove Trimbox:

```bash
./uninstall.sh
```
