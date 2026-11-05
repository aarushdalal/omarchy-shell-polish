#!/usr/bin/env python3
"""Verify a glass kit; --apply restores its selected files with recovery copies."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--kit', type=Path, default=Path(__file__).resolve().parent / 'restore-kit')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    kit = args.kit.resolve()
    manifest = json.loads((kit / 'file-index.json').read_text())
    home = Path.home().resolve()
    verified = []
    for item in manifest['files']:
        relative = Path(item['path'])
        if relative.is_absolute() or '..' in relative.parts:
            raise ValueError('Unsafe restore path')
        source = kit / 'files' / relative
        data = source.read_bytes()
        if hashlib.sha256(data).hexdigest() != item['sha256']:
            raise ValueError('Checksum mismatch: ' + str(relative))
        destination = home / relative
        if not destination.resolve(strict=False).is_relative_to(home):
            raise ValueError('Restore destination leaves the user home')
        if item['text']:
            data = data.decode().replace(manifest['source_home'], str(home)).encode()
        verified.append((item, destination, data))
    if not args.apply:
        print(f'Verified {len(verified)} glass files. No changes made. Use --apply after restoring the desktop base.')
        return
    recovery = home / '.local/state/omarchy' / ('glass-restore-' + time.strftime('%Y%m%d-%H%M%S'))
    for item, destination, data in verified:
        if destination.exists() or destination.is_symlink():
            before = recovery / item['path']
            before.parent.mkdir(parents=True, exist_ok=True)
            if destination.is_symlink():
                before.symlink_to(destination.readlink())
                destination.unlink()
            else:
                shutil.copy2(destination, before)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        destination.chmod(item['mode'])
    print(f'Restored {len(verified)} glass files. Prior files are in {recovery}. Reopen desktop apps to activate.')


if __name__ == '__main__':
    main()
