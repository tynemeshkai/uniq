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
VENV_DIR="$SCRIPT_DIR/.venv"

echo "============================================"
echo "  Building $APP_NAME"
echo "============================================"

# ─── Step 1: Create venv & install dependencies ─────────
echo ""
echo "[1/5] Setting up Python virtual environment..."

if [ ! -d "$VENV_DIR" ]; then
    echo "  Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate venv
source "$VENV_DIR/bin/activate"

echo "  Installing dependencies..."
pip install --quiet --upgrade pip
pip install --quiet PyQt6 pyinstaller

echo "  Python: $(python3 --version)"
echo "  pip packages installed."

# ─── Step 2: Download ffmpeg if not present ──────────────
echo ""
echo "[2/5] Checking ffmpeg binaries..."

if [ ! -f "$FFMPEG_DIR/ffmpeg" ] || [ ! -f "$FFMPEG_DIR/ffprobe" ]; then
    echo "  Downloading ffmpeg static build for macOS..."
    mkdir -p "$FFMPEG_DIR"

    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        echo "  Detected Apple Silicon (arm64)"
    else
        echo "  Detected Intel (x86_64)"
    fi

    # evermeet.cx provides macOS universal static builds
    FFMPEG_URL="https://evermeet.cx/ffmpeg/ffmpeg-7.1.1.zip"
    FFPROBE_URL="https://evermeet.cx/ffmpeg/ffprobe-7.1.1.zip"

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
echo "[3/5] Generating app icon..."

python3 "$SRC_DIR/gen_icns.py"

# ─── Step 4: Build with PyInstaller ─────────────────────
echo ""
echo "[4/5] Building .app with PyInstaller..."

# Clean previous builds
rm -rf "$DIST_DIR"

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

# ─── Step 5: Create DMG ─────────────────────────────────
echo ""
echo "[5/5] Creating DMG..."

DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
rm -f "$DMG_PATH"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DIST_DIR/$APP_NAME.app" \
    -ov -format UDZO \
    "$DMG_PATH"

# Deactivate venv
deactivate

echo ""
echo "============================================"
echo "  BUILD COMPLETE!"
echo "============================================"
echo ""
echo "  App: $DIST_DIR/$APP_NAME.app"
echo "  DMG: $DMG_PATH"
echo ""
echo "  Copy the .dmg or .app to any Mac — it will"
echo "  work without Python or ffmpeg installed."
echo ""
