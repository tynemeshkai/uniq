"""
Generate macOS .icns app icon from the programmatic icon.
Run on macOS to produce the icon file.
Falls back to PNG if iconutil is not available (non-macOS).
"""

import os
import sys
import subprocess
import tempfile

# Ensure we can import from the same directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PyQt6.QtWidgets import QApplication
from PyQt6.QtCore import QSize
from PyQt6.QtGui import QPixmap

from icons import app_icon


def generate_icns(output_dir: str):
    """Generate .icns file for macOS app bundle."""
    app = QApplication.instance() or QApplication(sys.argv[:1])

    os.makedirs(output_dir, exist_ok=True)
    icon = app_icon(1024)

    # Required sizes for iconset
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    retina_map = {
        16: "icon_16x16.png",
        32: "icon_16x16@2x.png",  # 32 is also 16@2x
        64: "icon_32x32@2x.png",  # 64 is also 32@2x
        128: "icon_128x128.png",
        256: "icon_128x128@2x.png",  # 256 is also 128@2x
        512: "icon_256x256@2x.png",  # 512 is also 256@2x
        1024: "icon_512x512@2x.png",
    }
    standard_map = {
        16: "icon_16x16.png",
        32: "icon_32x32.png",
        128: "icon_128x128.png",
        256: "icon_256x256.png",
        512: "icon_512x512.png",
    }

    # Create iconset directory
    iconset_dir = os.path.join(output_dir, "app_icon.iconset")
    os.makedirs(iconset_dir, exist_ok=True)

    # Generate all required sizes
    all_files = {}
    all_files.update(standard_map)
    all_files.update(retina_map)

    for size, filename in all_files.items():
        pixmap = icon.pixmap(QSize(size, size))
        filepath = os.path.join(iconset_dir, filename)
        pixmap.save(filepath, "PNG")

    # Try to use iconutil (macOS only)
    icns_path = os.path.join(output_dir, "app_icon.icns")
    try:
        subprocess.run(
            ["iconutil", "-c", "icns", iconset_dir, "-o", icns_path],
            check=True,
            capture_output=True,
        )
        print(f"Generated .icns: {icns_path}")
    except (FileNotFoundError, subprocess.CalledProcessError):
        # Not on macOS or iconutil failed — save as PNG fallback
        fallback = os.path.join(output_dir, "app_icon.png")
        icon.pixmap(QSize(512, 512)).save(fallback, "PNG")
        # Also create a dummy .icns (copy the PNG, PyInstaller will handle it)
        import shutil
        shutil.copy(fallback, icns_path)
        print(f"iconutil not available (not macOS?). Created fallback: {icns_path}")


if __name__ == "__main__":
    # Default output to build/ directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(os.path.dirname(script_dir), "build")
    generate_icns(output_dir)
