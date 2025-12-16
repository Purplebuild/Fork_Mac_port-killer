#!/bin/bash

# Build script for PortKiller.app
set -e

APP_NAME="PortKiller"
BUNDLE_ID="com.portkiller.app"
BUILD_DIR=".build/release"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building release binary..."
swift build -c release

echo "📦 Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$CONTENTS_DIR/Frameworks"

echo "📋 Copying files..."
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"
cp "Resources/Info.plist" "$CONTENTS_DIR/"

# Debug: List contents of build directory
echo "📂 Contents of $BUILD_DIR:"
ls -la "$BUILD_DIR/" | grep -E "\.bundle$|^total" || echo "  (no bundles found)"

# Copy icon if exists
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/"
fi

# Copy SPM resource bundle (contains toolbar icons)
if [ -d "$BUILD_DIR/PortKiller_PortKiller.bundle" ]; then
    echo "  → Copying PortKiller_PortKiller.bundle"
    cp -r "$BUILD_DIR/PortKiller_PortKiller.bundle" "$RESOURCES_DIR/"
else
    echo "  ⚠️  PortKiller_PortKiller.bundle not found"
fi

# Copy KeyboardShortcuts resource bundle (contains localizations)
if [ -d "$BUILD_DIR/KeyboardShortcuts_KeyboardShortcuts.bundle" ]; then
    echo "  → Copying KeyboardShortcuts_KeyboardShortcuts.bundle"
    cp -r "$BUILD_DIR/KeyboardShortcuts_KeyboardShortcuts.bundle" "$RESOURCES_DIR/"
else
    echo "  ⚠️  KeyboardShortcuts_KeyboardShortcuts.bundle not found"
fi

# Copy Defaults resource bundle (contains PrivacyInfo)
if [ -d "$BUILD_DIR/Defaults_Defaults.bundle" ]; then
    echo "  → Copying Defaults_Defaults.bundle"
    cp -r "$BUILD_DIR/Defaults_Defaults.bundle" "$RESOURCES_DIR/"
else
    echo "  ⚠️  Defaults_Defaults.bundle not found"
fi

# Download and copy Sparkle framework from official release (preserves symlinks)
SPARKLE_VERSION="2.8.1"
SPARKLE_CACHE="/tmp/Sparkle-${SPARKLE_VERSION}"

if [ ! -d "$SPARKLE_CACHE/Sparkle.framework" ]; then
    echo "📥 Downloading Sparkle ${SPARKLE_VERSION}..."
    curl -L -o /tmp/Sparkle.tar.xz "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"
    mkdir -p "$SPARKLE_CACHE"
    tar -xf /tmp/Sparkle.tar.xz -C "$SPARKLE_CACHE"
    rm /tmp/Sparkle.tar.xz
fi

echo "📦 Copying Sparkle.framework..."
ditto "$SPARKLE_CACHE/Sparkle.framework" "$CONTENTS_DIR/Frameworks/Sparkle.framework"

# Add rpath so executable can find the framework
echo "🔗 Setting up framework path..."
install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/$APP_NAME" 2>/dev/null || true

# Verify bundles were copied
echo "📂 Contents of $RESOURCES_DIR:"
ls -la "$RESOURCES_DIR/"

echo "🔏 Signing app bundle..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ App bundle created at: $APP_DIR"
echo ""
echo "To install, run:"
echo "  cp -r $APP_DIR /Applications/"
echo ""
echo "Or open directly:"
echo "  open $APP_DIR"
