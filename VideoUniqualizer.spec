# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller spec file for Video Uniqualizer.
Use this for manual builds: pyinstaller VideoUniqualizer.spec
"""

import os
import sys

block_cipher = None

SCRIPT_DIR = os.path.dirname(os.path.abspath(SPEC))
SRC_DIR = os.path.join(SCRIPT_DIR, 'src')
FFMPEG_DIR = os.path.join(SCRIPT_DIR, 'ffmpeg_bin')

# Data files to include
datas = [
    (os.path.join(SRC_DIR, 'engine.py'), '.'),
    (os.path.join(SRC_DIR, 'icons.py'), '.'),
    (os.path.join(SRC_DIR, 'styles.py'), '.'),
]

# Add ffmpeg binaries if they exist
if os.path.isfile(os.path.join(FFMPEG_DIR, 'ffmpeg')):
    datas.append((os.path.join(FFMPEG_DIR, 'ffmpeg'), 'ffmpeg'))
if os.path.isfile(os.path.join(FFMPEG_DIR, 'ffprobe')):
    datas.append((os.path.join(FFMPEG_DIR, 'ffprobe'), 'ffmpeg'))

# Icon file
icon_file = os.path.join(SCRIPT_DIR, 'build', 'app_icon.icns')
if not os.path.isfile(icon_file):
    icon_file = None

a = Analysis(
    [os.path.join(SRC_DIR, 'main.py')],
    pathex=[SRC_DIR],
    binaries=[],
    datas=datas,
    hiddenimports=[
        'PyQt6.sip',
        'PyQt6.QtCore',
        'PyQt6.QtGui',
        'PyQt6.QtWidgets',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Video Uniqualizer',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=icon_file,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='Video Uniqualizer',
)

app = BUNDLE(
    coll,
    name='Video Uniqualizer.app',
    icon=icon_file,
    bundle_identifier='com.uniqualizer.video',
    info_plist={
        'NSHighResolutionCapable': True,
        'CFBundleShortVersionString': '1.0.0',
        'CFBundleVersion': '1.0.0',
        'NSHumanReadableCopyright': 'Video Uniqualizer',
        'LSMinimumSystemVersion': '10.15',
    },
)
