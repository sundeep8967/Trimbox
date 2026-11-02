#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Trimbox"
DIST_DIR="$SCRIPT_DIR/dist"
mkdir -p "$DIST_DIR"

build_for_arch() {
    local ARCH="$1"
    local TARGET_TRIPLE="$2"
    local DMG_NAME="$3"
    
    echo "=============================================="
    echo "==> Building $APP_NAME for $ARCH ($TARGET_TRIPLE)..."
    echo "=============================================="
    
    local STAGING="$SCRIPT_DIR/build/staging_$ARCH"
    local APP_BUNDLE="$STAGING/$APP_NAME.app"
    
    rm -rf "$STAGING"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    
    # Compile for target architecture
    swiftc -target "$TARGET_TRIPLE" -O "$SCRIPT_DIR"/Sources/Trimbox/*.swift -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    
    # Copy Info.plist
    cp "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
    
    # Create symlink to /Applications for easy drag-and-drop
    ln -s /Applications "$STAGING/Applications"
    
    # Copy quick installer and documentation
    cp "$SCRIPT_DIR/install.sh" "$STAGING/Install Service.command"
    chmod +x "$STAGING/Install Service.command"
    cp "$SCRIPT_DIR/README.md" "$STAGING/README.txt"
    
    echo "==> Packaging $DMG_NAME..."
    rm -f "$DIST_DIR/$DMG_NAME"
    hdiutil create -volname "$APP_NAME ($ARCH)" -srcfolder "$STAGING" -ov -format UDZO "$DIST_DIR/$DMG_NAME"
    
    echo "==> Created $DIST_DIR/$DMG_NAME"
    rm -rf "$STAGING"
}

# 1. Intel (x86_64)
build_for_arch "Intel-x86_64" "x86_64-apple-macosx12.0" "Trimbox-Intel-x86_64.dmg"

# 2. Apple Silicon (arm64)
build_for_arch "AppleSilicon-arm64" "arm64-apple-macosx12.0" "Trimbox-AppleSilicon-arm64.dmg"

echo ""
echo "=============================================="
echo "  All DMGs built successfully in $DIST_DIR:"
ls -lh "$DIST_DIR"/*.dmg
echo "=============================================="
