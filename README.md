# Video Uniqualizer

Standalone macOS application for video uniqualization based on HYBRID V8.0 engine.

## Features

- Select multiple video files for batch processing
- Choose output folder
- Adjustable parameters (geometry, color, effects, output settings)
- V8.0 defaults loaded as template on startup
- ffmpeg bundled inside the app — no external dependencies needed
- Skeuomorphic dark UI design

## Building the .app

### Prerequisites

- macOS 10.15+
- Python 3.9+ (only needed for building, not for running the app)
- pip

### Quick Build

```bash
chmod +x build.sh
./build.sh
```

This will:
1. Install Python dependencies (PyQt6, PyInstaller)
2. Download ffmpeg/ffprobe static binaries
3. Generate the app icon (.icns)
4. Package everything into `dist/Video Uniqualizer.app`

### Manual Build

If the automated script doesn't work, you can build step by step:

```bash
# 1. Install dependencies
pip3 install PyQt6 pyinstaller

# 2. Download ffmpeg static builds from https://evermeet.cx/ffmpeg/
#    Place ffmpeg and ffprobe into ffmpeg_bin/ directory

# 3. Generate icon
python3 src/gen_icns.py

# 4. Build
pyinstaller VideoUniqualizer.spec
```

### Providing your own ffmpeg

If you already have ffmpeg installed or want a specific version:

```bash
mkdir -p ffmpeg_bin
cp $(which ffmpeg) ffmpeg_bin/
cp $(which ffprobe) ffmpeg_bin/
```

## Distribution

The built `Video Uniqualizer.app` in `dist/` is fully self-contained.
Copy it to any Mac and it will run without needing Python or ffmpeg installed.

To create a DMG for distribution:

```bash
hdiutil create -volname "Video Uniqualizer" \
  -srcfolder "dist/Video Uniqualizer.app" \
  -ov -format UDZO \
  "dist/Video Uniqualizer.dmg"
```

## Development

Run the app directly (requires Python + PyQt6 + ffmpeg in PATH):

```bash
cd src
python3 main.py
```

## Project Structure

```
├── build.sh              # Automated build script
├── VideoUniqualizer.spec  # PyInstaller spec for manual builds
├── requirements.txt       # Python dependencies
├── src/
│   ├── main.py           # Application entry point + GUI
│   ├── engine.py         # Video processing engine (HYBRID V8.0)
│   ├── icons.py          # Programmatically drawn icons
│   ├── styles.py         # Skeuomorphic Qt stylesheet
│   └── gen_icns.py       # macOS .icns icon generator
└── ffmpeg_bin/           # ffmpeg binaries (created during build)
```
