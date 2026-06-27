#!/bin/bash
set -euo pipefail

REPO="jint233/cmd-tab-ultra"
BINARY_NAME="CmdTabUltra"
APP_BUNDLE="$HOME/Applications/CmdTabUltra.app"
BINARY="$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
PLIST_LABEL="com.jint233.cmdtabultra"
PLIST_FILE="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
LAUNCHD_UID="gui/$(id -u)"
RESET_ACCESSIBILITY="${RESET_ACCESSIBILITY:-1}"

# Parse arguments
LOCAL_MODE=false
if [[ "${1:-}" == "--local" ]]; then
  LOCAL_MODE=true
fi

# Install app bundle

if [ "$LOCAL_MODE" = true ]; then
  echo "Installing from local build..."
  if [ ! -d "dist/CmdTabUltra.app" ]; then
    echo "Error: dist/CmdTabUltra.app not found. Please run 'make package' first." >&2
    exit 1
  fi
  echo "Installing to $APP_BUNDLE..."
  rm -rf "$APP_BUNDLE"
  cp -R "dist/CmdTabUltra.app" "$APP_BUNDLE"
else
  echo "Checking latest release on GitHub..."
  LATEST_JSON=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")
  LATEST_VERSION=$(echo "$LATEST_JSON" | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')

  if [ -f "$PLIST_FILE" ]; then
    INSTALLED_VERSION=$(/usr/libexec/PlistBuddy -c "Print :Version" "$PLIST_FILE" 2>/dev/null || echo "")
    if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
      echo "✅ CmdTabUltra $LATEST_VERSION is already up to date."
      exit 0
    fi
  fi

  echo "Downloading v$LATEST_VERSION..."
  DOWNLOAD_URL=$(echo "$LATEST_JSON" \
    | grep '"browser_download_url"' | grep 'universal\.zip' | cut -d'"' -f4)

  if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: could not find a release asset. Check https://github.com/$REPO/releases" >&2
    exit 1
  fi

  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT

  curl -fsSL "$DOWNLOAD_URL" -o "$TMP/release.zip"
  echo "Extracting app bundle..."
  unzip -q "$TMP/release.zip" -d "$TMP"

  echo "Installing to $APP_BUNDLE..."
  rm -rf "$APP_BUNDLE"
  cp -R "$TMP/CmdTabUltra.app" "$APP_BUNDLE"
fi

INSTALLED_APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "1.0.0")

# Ensure correct permissions
chmod +x "$BINARY"
xattr -dr com.apple.quarantine "$APP_BUNDLE" 2>/dev/null || true
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

# Install LaunchAgent

echo "Installing LaunchAgent..."
launchctl bootout "$LAUNCHD_UID" "$PLIST_FILE" 2>/dev/null || true
if [ "$RESET_ACCESSIBILITY" != "0" ]; then
  tccutil reset Accessibility "$PLIST_LABEL" 2>/dev/null || true
fi

mkdir -p "$(dirname "$PLIST_FILE")"
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>Version</key>
    <string>$INSTALLED_APP_VERSION</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY</string>
        <string>--agent</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/CmdTabUltra.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/CmdTabUltra.log</string>
</dict>
</plist>
EOF

launchctl enable "$LAUNCHD_UID/$PLIST_LABEL"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
open "$APP_BUNDLE" 2>/dev/null || true

echo ""
echo "✅ CmdTabUltra installed successfully."
echo "Please grant Accessibility permission, then start the service from CmdTabUltra."
echo ""
