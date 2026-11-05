#!/usr/bin/env python3
"""Build an isolated Linux ChatGPT glass runtime, keeping the installed app intact.

The executable and its security fuses are byte-identical to the installed runtime.
Only native background transparency, main-window background paint change in
a user-owned ASAR copy. All file integrity records are retained and updated for
the changed module; renderer sandbox and isolation policies remain intact.
"""
from pathlib import Path
import fcntl
import hashlib
import json
import mmap
import os
import shutil
import struct
import subprocess
import sys
import tempfile

SOURCE = Path('/usr/lib/chatgpt')
AUTHOR = Path(__file__).resolve()
PREVIEW = '--preview' in sys.argv
CACHE = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'chatgpt-glass'
RUNTIME = CACHE / ('preview-runtime' if PREVIEW else 'runtime')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def inspect_archive(path):
    with path.open('rb') as f:
        sizes = struct.unpack('<IIII', f.read(16))
        metadata = f.read(sizes[3])
    return sizes, metadata, json.loads(metadata)


def patch_archive(path):
    sizes, metadata, header = inspect_archive(path)
    files = header['files']['.vite']['files']['build']['files']
    candidates = [(n, e) for n, e in files.items() if n.startswith('early-bootstrap-') and n.endswith('.js')]
    matches = []
    with path.open('rb') as f:
        for name, entry in candidates:
            f.seek(8 + sizes[1] + int(entry['offset']))
            code = f.read(entry['size']).decode()
            marker = 'return("win32"!==process.platform||"enabled"===ea.app.getGPUFeatureStatus().gpu_compositing)&&ea.BrowserWindow.isSystemBackdropSupported()'
            if marker in code:
                matches.append((entry, code, marker))
    if len(matches) != 1:
        raise RuntimeError('ChatGPT window code changed; opening the installed app instead')
    entry, code, marker = matches[0]
    old_entry = json.dumps(entry, separators=(',', ':')).encode()
    option = 'return{titleBarStyle:"hidden",titleBarOverlay:eRR(n)}'
    if code.count(marker) != 1 or code.count(option) != 2:
        raise RuntimeError('ChatGPT window options changed; opening the installed app instead')
    code = code.replace(marker, 'return"linux"===process.platform')
    code = code.replace(option, 'return{transparent:"linux"===r,titleBarStyle:"hidden",titleBarOverlay:eRR(n)}')
    css = ('html,body,#root{background:transparent!important}'
           'body{background:rgba(0,0,0,.74)!important}'
           'main.bg-surface,main[class*="_MainContentSurface"]{background:transparent!important}')
    hook = 'let j=F.webContents;'
    if code.count(hook) != 1:
        raise RuntimeError('ChatGPT web contents setup changed')
    code = code.replace(hook, hook + '("primary"===d||"detached"===d)&&j.on("did-finish-load",()=>{j.insertCSS(' + json.dumps(css) + ',{cssOrigin:"user"}).catch(()=>{})});')
    data = code.encode()
    block = entry.get('integrity', {}).get('blockSize', 4194304)
    old_start = 8 + sizes[1]
    entry['offset'] = str(path.stat().st_size - old_start)
    entry['size'] = len(data)
    entry['integrity'] = {'algorithm': 'SHA256', 'hash': sha(data), 'blockSize': block,
                          'blocks': [sha(data[i:i + block]) for i in range(0, len(data), block)]}
    metadata = json.dumps(header, separators=(',', ':'), ensure_ascii=False).encode()
    padded = metadata + b'\0' * (-len(metadata) % 4)
    pickle = struct.pack('<II', 4 + len(padded), len(metadata)) + padded
    rebuilt = path.with_suffix('.rebuilding')
    try:
        with path.open('rb') as original, rebuilt.open('wb') as output:
            output.write(struct.pack('<II', 4, len(pickle)) + pickle)
            original.seek(old_start)
            shutil.copyfileobj(original, output, 4 * 1024 * 1024)
            output.write(data)
            output.flush()
            os.fsync(output.fileno())
        checked_sizes, _, checked_header = inspect_archive(rebuilt)
        with rebuilt.open('rb') as f:
            f.seek(8 + checked_sizes[1] + int(entry['offset']))
            actual = f.read(entry['size'])
        if sha(actual) != entry['integrity']['hash']:
            raise RuntimeError('ChatGPT glass archive verification failed')
        rebuilt.replace(path)
    finally:
        rebuilt.unlink(missing_ok=True)


def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    with (CACHE / 'build.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        original = SOURCE / 'ChatGPT'
        archive = SOURCE / 'resources/app.asar'
        _, metadata, _ = inspect_archive(archive)
        stamp = {'archive_header': sha(metadata), 'archive_size': archive.stat().st_size,
                 'binary': [original.stat().st_size, original.stat().st_mtime_ns],
                 'builder': sha(AUTHOR.read_bytes()), 'preview': PREVIEW}
        marker = RUNTIME / 'glass-source.json'
        if marker.is_file() and json.loads(marker.read_text()) == stamp:
            print(RUNTIME / 'ChatGPT')
            return
        temporary = Path(tempfile.mkdtemp(prefix='runtime-', dir=CACHE))
        try:
            for item in SOURCE.iterdir():
                if item.name == 'resources':
                    continue
                if item.name == 'ChatGPT':
                    subprocess.run(['cp', '--reflink=auto', '--preserve=mode', str(item), str(temporary / item.name)], check=True)
                else:
                    (temporary / item.name).symlink_to(item, target_is_directory=item.is_dir())
            resources = temporary / 'resources'
            resources.mkdir()
            for item in (SOURCE / 'resources').iterdir():
                target = resources / item.name
                if item.name == 'app.asar':
                    subprocess.run(['cp', '--reflink=auto', '--preserve=mode', str(item), str(target)], check=True)
                    patch_archive(target)
                elif item.name == 'owl-app.ini':
                    text = item.read_text()
                    if PREVIEW:
                        text = text.replace('UserDataDirectoryName=Codex', 'UserDataDirectoryName=CodexGlassPreview')
                    target.write_text(text)
                else:
                    target.symlink_to(item, target_is_directory=item.is_dir())
            # No flags, security fuses, preload policies or renderer isolation are changed.
            with original.open('rb') as f, (temporary / 'ChatGPT').open('rb') as g:
                with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as a, mmap.mmap(g.fileno(), 0, access=mmap.ACCESS_READ) as b:
                    if sha(a) != sha(b):
                        raise RuntimeError('ChatGPT executable copy differs from the installed runtime')
            (temporary / 'glass-source.json').write_text(json.dumps(stamp, indent=2) + '\n')
            previous = CACHE / ('preview-previous' if PREVIEW else 'previous')
            if previous.exists():
                shutil.rmtree(previous)
            if RUNTIME.exists():
                RUNTIME.rename(previous)
            temporary.rename(RUNTIME)
            if previous.exists():
                shutil.rmtree(previous)
            print(RUNTIME / 'ChatGPT')
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)


if __name__ == '__main__':
    main()
