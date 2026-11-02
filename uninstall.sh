#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Trimbox"
TARGET_APP="$HOME/Applications/$APP_NAME.app"
PLIST_FILE="$HOME/Library/LaunchAgents/com.trimbox.app.plist"
USER_ID="$(id -u)"

echo "==> Stopping Trimbox service..."
launchctl bootout "gui/$USER_ID/$PLIST_FILE" 2>/dev/null || launchctl unload "$PLIST_FILE" 2>/dev/null || true
pkill -x "$APP_NAME" 2>/dev/null || true

echo "==> Removing LaunchAgent..."
rm -f "$PLIST_FILE"

echo "==> Removing application bundle..."
rm -rf "$TARGET_APP"

echo "==> Trimbox has been completely uninstalled."
