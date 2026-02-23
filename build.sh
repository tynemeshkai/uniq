#!/bin/bash
# ============================================================
#   Build Video Uniqualizer.app for macOS
#   Run this script on a Mac to produce a self-contained .app
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Video Uniqualizer"
SRC_DIR="$SCRIPT_DIR/src"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
FFMPEG_DIR="$SCRIPT_DIR/ffmpeg_bin"

echo "============================================"
echo "  Building $APP_NAME"
echo "============================================"

# ─── Step 1: Check/install Python dependencies ──────────
echo ""
echo "[1/4] Checking Python dependencies..."

pip3 install --quiet PyQt6 pyinstaller

# ─── Step 2: Download ffmpeg if not present ──────────────
echo ""
echo "[2/4] Checking ffmpeg binaries..."

if [ ! -f "$FFMPEG_DIR/ffmpeg" ] || [ ! -f "$FFMPEG_DIR/ffprobe" ]; then
    echo "  Downloading ffmpeg static build for macOS..."
    mkdir -p "$FFMPEG_DIR"

    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        echo "  Detected Apple Silicon (arm64)"
        # evermeet.cx provides macOS static builds
        FFMPEG_URL="https://evermeet.cx/ffmpeg/ffmpeg-7.1.1.zip"
        FFPROBE_URL="https://evermeet.cx/ffmpeg/ffprobe-7.1.1.zip"
    else
        echo "  Detected Intel (x86_64)"
        FFMPEG_URL="https://evermeet.cx/ffmpeg/ffmpeg-7.1.1.zip"
        FFPROBE_URL="https://evermeet.cx/ffmpeg/ffprobe-7.1.1.zip"
    fi

    # Download ffmpeg
    if [ ! -f "$FFMPEG_DIR/ffmpeg" ]; then
        echo "  Downloading ffmpeg..."
        curl -L -o "$FFMPEG_DIR/ffmpeg.zip" "$FFMPEG_URL"
        unzip -o "$FFMPEG_DIR/ffmpeg.zip" -d "$FFMPEG_DIR/"
        rm -f "$FFMPEG_DIR/ffmpeg.zip"
        chmod +x "$FFMPEG_DIR/ffmpeg"
    fi

    # Download ffprobe
    if [ ! -f "$FFMPEG_DIR/ffprobe" ]; then
        echo "  Downloading ffprobe..."
        curl -L -o "$FFMPEG_DIR/ffprobe.zip" "$FFPROBE_URL"
        unzip -o "$FFMPEG_DIR/ffprobe.zip" -d "$FFMPEG_DIR/"
        rm -f "$FFMPEG_DIR/ffprobe.zip"
        chmod +x "$FFMPEG_DIR/ffprobe"
    fi

    echo "  ffmpeg binaries ready."
else
    echo "  ffmpeg binaries already present."
fi

# Verify
echo "  ffmpeg: $("$FFMPEG_DIR/ffmpeg" -version 2>&1 | head -1)" || echo "  WARNING: Could not verify ffmpeg"
echo "  ffprobe: $("$FFMPEG_DIR/ffprobe" -version 2>&1 | head -1)" || echo "  WARNING: Could not verify ffprobe"

# ─── Step 3: Generate app icon (icns) ───────────────────
echo ""
echo "[3/4] Generating app icon..."

python3 "$SRC_DIR/gen_icns.py"

# ─── Step 4: Build with PyInstaller ─────────────────────
echo ""
echo "[4/4] Building .app with PyInstaller..."

# Clean previous builds
rm -rf "$BUILD_DIR" "$DIST_DIR"

pyinstaller \
    --name "$APP_NAME" \
    --windowed \
    --onedir \
    --icon "$BUILD_DIR/app_icon.icns" \
    --add-data "$FFMPEG_DIR/ffmpeg:ffmpeg" \
    --add-data "$FFMPEG_DIR/ffprobe:ffmpeg" \
    --add-data "$SRC_DIR/engine.py:." \
    --add-data "$SRC_DIR/icons.py:." \
    --add-data "$SRC_DIR/styles.py:." \
    --hidden-import PyQt6.sip \
    --hidden-import PyQt6.QtCore \
    --hidden-import PyQt6.QtGui \
    --hidden-import PyQt6.QtWidgets \
    --noconfirm \
    --clean \
    --distpath "$DIST_DIR" \
    --workpath "$BUILD_DIR/pyinstaller" \
    --specpath "$BUILD_DIR" \
    "$SRC_DIR/main.py"

echo ""
echo "============================================"
echo "  BUILD COMPLETE!"
echo "  App: $DIST_DIR/$APP_NAME.app"
echo "============================================"
echo ""
echo "To distribute, you can:"
echo "  1. Copy the .app to another Mac"
echo "  2. Or create a DMG: hdiutil create -volname '$APP_NAME' -srcfolder '$DIST_DIR/$APP_NAME.app' -ov -format UDZO '$DIST_DIR/$APP_NAME.dmg'"
