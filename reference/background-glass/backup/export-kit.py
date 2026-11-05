#!/usr/bin/env python3
"""Collect only the authored glass configuration and its small restore dependencies."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import stat
import tempfile

HOME = Path.home()
BASE = Path(__file__).resolve().parent
SOURCES = [
    '.config/hypr/shared/visual-polish.lua',
    '.config/omarchy/glass-apps/universal-glass.py',
    '.config/omarchy/glass-apps/universal-glass.json',
    '.config/omarchy/glass-apps/recipes',
    '.config/systemd/user/daemon-glass.service',
    '.local/bin/daemon-glass',
    '.config/omarchy-screensaver/config.toml',
    '.local/share/omarchy-screensaver/omarchy_screensaver/config.py',
    '.local/share/omarchy-screensaver/omarchy_screensaver/window.py',
    '.local/share/omarchy-screensaver/omarchy_screensaver/modes/base.py',
    '.config/spicetify/Extensions/daemon-spotify-sync.js',
    '.config/spicetify/Themes/caelestia',
    '.config/spicetify/config-xpui.ini',
    '.config/spicetify/daemon-glass',
    '.config/Antigravity/daemon-glass',
    '.config/omarchy/glass-apps/chatgpt/build-runtime.py',
    '.config/omarchy/glass-apps/export-kit.py',
    '.config/omarchy/glass-apps/restore.py',
    '.config/omarchy/glass-apps/README.md',
    '.config/gtk-4.0/gtk.css',
    '.config/gtk-4.0/omarchy-palette.css',
    '.config/gtk-4.0/nautilus-glass.css',
    '.config/gtk-4.0/thunar.css',
    '.config/foot/foot.ini',
    '.config/ghostty/config',
    '.config/kitty/kitty.conf',
    '.config/alacritty/alacritty.toml',
    '.local/state/omarchy/current/wallpaper-foot.ini',
    '.local/bin/spotify',
    '.local/bin/antigravity',
    '.local/bin/chatgpt',
    '.local/bin/omarchy-gtk4-theme-sync',
    '.local/share/applications/antigravity.desktop',
    '.local/share/applications/chatgpt.desktop',
]


def main():
    stage = Path(tempfile.mkdtemp(prefix='.glass-kit-', dir=BASE))
    records = []
    try:
        for name in SOURCES:
            source = HOME / name
            if not source.exists():
                raise RuntimeError('Missing glass source: ' + name)
            files = sorted(p for p in source.rglob('*') if p.is_file()) if source.is_dir() else [source]
            for file in files:
                if '__pycache__' in file.parts or file.suffix in ('.pyc', '.log'):
                    continue
                relative = file.relative_to(HOME)
                data = file.read_bytes()
                dest = stage / 'files' / relative
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
                mode = stat.S_IMODE(file.stat().st_mode)
                dest.chmod(mode)
                try:
                    data.decode('utf-8')
                    text = True
                except UnicodeDecodeError:
                    text = False
                records.append({'path': str(relative), 'sha256': hashlib.sha256(data).hexdigest(),
                                'bytes': len(data), 'mode': mode, 'text': text})
        manifest = {'schema': 1, 'source_home': str(HOME), 'platform': 'Linux x86_64, Omarchy/DaemonOS',
                    'files': records, 'scope': 'Glass configuration only; no account credentials or caches.'}
        (stage / 'file-index.json').write_text(json.dumps(manifest, indent=2) + '\n')
        destination = BASE / 'restore-kit'
        previous = BASE / '.previous-restore-kit'
        if previous.exists():
            shutil.rmtree(previous)
        if destination.exists():
            destination.rename(previous)
        stage.rename(destination)
        if previous.exists():
            shutil.rmtree(previous)
        print(json.dumps({'files': len(records), 'bytes': sum(x['bytes'] for x in records), 'path': str(destination)}))
    finally:
        if stage.exists():
            shutil.rmtree(stage)


if __name__ == '__main__':
    main()
