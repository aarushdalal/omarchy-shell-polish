#!/usr/bin/env python3
"""Rebuild a disposable, user-owned Antigravity glass runtime from its installed app.

Only window construction and background CSS injection change. The system package,
login data, application settings, renderer isolation and sandbox settings are retained.
The 219 MB executable is copied with Btrfs reflinks; the cache is not backed up.
"""
from pathlib import Path
import fcntl
import hashlib
import json
import os
import shutil
import struct
import subprocess
import tempfile

SOURCE = Path('/opt/Antigravity')
AUTHORED = Path(__file__).resolve().parent
CACHE = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'antigravity-glass'
RUNTIME = CACHE / 'runtime'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_asar(file):
    raw = file.read_bytes()
    _, header_size, _, length = struct.unpack('<IIII', raw[:16])
    return json.loads(raw[16:16 + length]), raw[8 + header_size:]


def entries(tree):
    for value in tree.values():
        if 'files' in value:
            yield from entries(value['files'])
        elif 'offset' in value and not value.get('unpacked'):
            yield value


def build_asar(destination):
    header, content = read_asar(SOURCE / 'resources/app.asar')
    target = header['files']['dist']['files']['utils.js']
    offset, size = int(target['offset']), target['size']
    code = content[offset:offset + size].decode()
    options = '        backgroundColor,\n        trafficLightPosition:'
    hook = '    // Prevent the menu dropdown from being very wide due to long page titles'
    overlay = '                color: backgroundColor,'
    for marker in (options, hook, overlay):
        if code.count(marker) != 1:
            raise RuntimeError('The installed Antigravity window code changed; keeping the stock app.')
    code = code.replace(options, "        transparent: true,\n        backgroundColor: '#00000000',\n        trafficLightPosition:")
    code = code.replace(overlay, "                color: '#00000000',")
    code = code.replace(hook, '    require(' + json.dumps(str(AUTHORED / 'window-glass.cjs')) + ')(win);\n' + hook)
    replacement = code.encode()
    payloads = []
    cursor = 0
    for entry in sorted(entries(header['files']), key=lambda v: int(v['offset'])):
        start, length = int(entry['offset']), entry['size']
        data = replacement if entry is target else content[start:start + length]
        if entry is target:
            block = entry.get('integrity', {}).get('blockSize', 4194304)
            entry['integrity'] = {'algorithm': 'SHA256', 'hash': digest(data), 'blockSize': block,
                                  'blocks': [digest(data[i:i + block]) for i in range(0, len(data), block)]}
        entry['offset'], entry['size'] = str(cursor), len(data)
        cursor += len(data)
        payloads.append(data)
    metadata = json.dumps(header, separators=(',', ':'), ensure_ascii=False).encode()
    padded = metadata + b'\0' * (-len(metadata) % 4)
    pickle = struct.pack('<II', 4 + len(padded), len(metadata)) + padded
    destination.write_bytes(struct.pack('<II', 4, len(pickle)) + pickle + b''.join(payloads))
    # Read the finished archive and verify every packed file, including the changed entry.
    verified_header, verified_content = read_asar(destination)
    for entry in entries(verified_header['files']):
        integrity = entry.get('integrity')
        if integrity and integrity.get('algorithm') == 'SHA256':
            start, length = int(entry['offset']), entry['size']
            if digest(verified_content[start:start + length]) != integrity['hash']:
                raise RuntimeError('Antigravity glass archive verification failed')


def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    with (CACHE / 'build.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        original = SOURCE / 'antigravity'
        binary = original.read_bytes()
        sentinel = b'dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX'
        start = binary.find(sentinel)
        if start < 0:
            raise RuntimeError('Unknown Electron fuse layout; keeping the stock app')
        fuse = binary[start + len(sentinel):]
        if fuse[0] != 1 or fuse[1] < 5 or fuse[6] != ord('0'):
            raise RuntimeError('This build requires embedded archive integrity; keeping the stock app')
        del binary
        stamp = {'archive': digest((SOURCE / 'resources/app.asar').read_bytes()),
                 'binary': [original.stat().st_size, original.stat().st_mtime_ns],
                 'builder': digest(Path(__file__).read_bytes()),
                 'helper': digest((AUTHORED / 'window-glass.cjs').read_bytes())}
        marker = RUNTIME / 'glass-source.json'
        if marker.is_file() and json.loads(marker.read_text()) == stamp:
            print(RUNTIME / 'antigravity')
            return
        temporary = Path(tempfile.mkdtemp(prefix='runtime-', dir=CACHE))
        try:
            for item in SOURCE.iterdir():
                if item.name == 'resources':
                    continue
                if item.name == 'antigravity':
                    subprocess.run(['cp', '--reflink=auto', '--preserve=mode', str(item), str(temporary / item.name)], check=True)
                else:
                    (temporary / item.name).symlink_to(item, target_is_directory=item.is_dir())
            resources = temporary / 'resources'
            resources.mkdir()
            for item in (SOURCE / 'resources').iterdir():
                if item.name != 'app.asar':
                    (resources / item.name).symlink_to(item, target_is_directory=item.is_dir())
            build_asar(resources / 'app.asar')
            (temporary / 'glass-source.json').write_text(json.dumps(stamp, indent=2) + '\n')
            old = CACHE / 'previous-runtime'
            if old.exists():
                shutil.rmtree(old)
            if RUNTIME.exists():
                RUNTIME.rename(old)
            temporary.rename(RUNTIME)
            if old.exists():
                shutil.rmtree(old)
            print(RUNTIME / 'antigravity')
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
