#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="WardleyMapsApp"
BUNDLE_ID="com.wardleymaps.native"
MODE="${1:-debug}"

bundle_app() {
    local bin_path="$1"
    local app_dir="${bin_path}/${APP_NAME}.app"
    local contents="${app_dir}/Contents"
    local macos="${contents}/MacOS"
    local resources="${contents}/Resources"

    rm -rf "$app_dir"
    mkdir -p "$macos" "$resources"

    cp "${bin_path}/${APP_NAME}" "${macos}/${APP_NAME}"

    cat > "${contents}/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>Wardley Maps</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>owm</string>
                <string>wardley</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>Wardley Map</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
        </dict>
    </array>
</dict>
</plist>
PLIST

    echo "$app_dir"
}

case "$MODE" in
    debug)
        echo "Building debug..."
        swift build
        bin_path="$(swift build --show-bin-path)"
        app_path="$(bundle_app "$bin_path")"
        echo ""
        echo "Run with: open ${app_path}"
        ;;
    release)
        echo "Building release..."
        swift build -c release
        bin_path="$(swift build -c release --show-bin-path)"
        app_path="$(bundle_app "$bin_path")"
        echo ""
        echo "Run with: open ${app_path}"
        ;;
    test)
        echo "Running tests..."
        swift test
        ;;
    run)
        echo "Building and running..."
        swift build
        bin_path="$(swift build --show-bin-path)"
        app_path="$(bundle_app "$bin_path")"
        open "$app_path"
        ;;
    clean)
        echo "Cleaning..."
        swift package clean
        ;;
    *)
        echo "Usage: $0 {debug|release|test|run|clean}"
        exit 1
        ;;
esac
