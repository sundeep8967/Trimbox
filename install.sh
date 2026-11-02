#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Trimbox"
TARGET_APP_DIR="$HOME/Applications"
TARGET_APP="$TARGET_APP_DIR/$APP_NAME.app"
BINARY_PATH="$TARGET_APP/Contents/MacOS/$APP_NAME"
PLIST_FILE="$HOME/Library/LaunchAgents/com.trimbox.app.plist"
USER_ID="$(id -u)"

echo "==> 1. Building $APP_NAME..."
"$SCRIPT_DIR/build.sh"

echo "==> 2. Installing to $TARGET_APP..."
mkdir -p "$TARGET_APP_DIR"
rm -rf "$TARGET_APP"
cp -R "$SCRIPT_DIR/build/$APP_NAME.app" "$TARGET_APP_DIR/"

# Symlink CLI tool to /usr/local/bin if available
if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    ln -sf "$BINARY_PATH" "/usr/local/bin/trimbox"
fi

echo "==> 3. Configuring LaunchAgent for auto-start at login..."
mkdir -p "$HOME/Library/LaunchAgents"

# Unload previous service if present
launchctl bootout "gui/$USER_ID/$PLIST_FILE" 2>/dev/null || launchctl unload "$PLIST_FILE" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true

cat <<EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.trimbox.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>$HOME/.trimbox/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.trimbox/stderr.log</string>
</dict>
</plist>
EOF

echo "==> 4. Starting $APP_NAME in background..."
# Stop any manual instances
pkill -x "$APP_NAME" 2>/dev/null || true

# Register & start via LaunchAgent (auto-starts on every login)
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE" 2>/dev/null || true

echo ""
echo "=========================================================="
echo "  Trimbox is now running natively in the background!"
echo "=========================================================="
echo "  • Paste Current:            ⌘V  (standard macOS)"
echo "  • Instant Paste Previous:   ⌥⌘V (Option + Cmd + V)"
echo "  • Instant Paste 2nd Prev:   ⌥⇧⌘V (Option + Shift + Cmd + V)"
echo "  • Cycle Clipboard:          ⌥⌘C"
echo "  • Toggle Queue Mode (FIFO): ⌥⌘Q"
echo ""
echo "  No windows to open. It runs automatically every time your Mac boots."
echo "  Menu bar icon (📋) available for settings and history inspection."
echo "=========================================================="
