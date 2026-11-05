#!/usr/bin/env python3
"""Capability-aware native glass setup and once-per-app desktop notifications.

Never changes whole-window opacity, opens applications, installs packages or
modifies unknown app binaries. State/inventory remains private on this machine.
"""
from pathlib import Path
import argparse
import configparser
import fcntl
import fnmatch
import html
import json
import os
import re
import shutil
import socket
import struct
import subprocess
import tempfile
import time

HOME = Path.home()
BASE = HOME / '.config/omarchy/glass-apps'
STATE = HOME / '.local/state/omarchy/glass-monitor'
COMPATIBILITY = {}


def archive_module(archive, directories, module_prefix, needle=None):
    with archive.open('rb') as stream:
        sizes = struct.unpack('<IIII', stream.read(16))
        if sizes[3] > 16*1024*1024:
            raise ValueError('Unsupported archive header')
        tree = json.loads(stream.read(sizes[3]))['files']
        for directory in directories:
            tree = tree[directory]['files']
        entries = [entry for name, entry in tree.items() if name.startswith(module_prefix) and name.endswith('.js')]
        matches = []; total = 0
        for entry in entries:
            total += entry['size']
            if entry['size'] > 20*1024*1024 or total > 64*1024*1024:
                raise ValueError('Unsupported module layout')
            stream.seek(8 + sizes[1] + int(entry['offset']))
            code = stream.read(entry['size']).decode()
            if needle is None or needle in code:
                matches.append(code)
        if len(matches) != 1:
            raise ValueError('Unsupported module layout')
        return matches[0]


def compatible(kind):
    paths = {'chatgpt': [Path('/usr/lib/chatgpt/resources/app.asar')],
             'antigravity': [Path('/opt/Antigravity/resources/app.asar')],
             'spotify': [Path('/opt/spotify/spotify'), Path('/opt/spotify/libcef.so'), HOME/'.local/bin/spotify']}[kind]
    try:
        signature = tuple((p.stat().st_size, p.stat().st_mtime_ns) for p in paths)
        if COMPATIBILITY.get(kind, (None,))[0] == signature:
            return COMPATIBILITY[kind][1]
        if kind == 'chatgpt':
            code = archive_module(paths[0], ('.vite', 'build'), 'early-bootstrap-', 'ea.BrowserWindow.isSystemBackdropSupported()')
            ok = code.count('return{titleBarStyle:"hidden",titleBarOverlay:eRR(n)}') == 2 and code.count('let j=F.webContents;') == 1 and 'ea.BrowserWindow.isSystemBackdropSupported()' in code
        elif kind == 'antigravity':
            code = archive_module(paths[0], ('dist',), 'utils.')
            ok = all(code.count(marker) == 1 for marker in ('        backgroundColor,\n        trafficLightPosition:', '                color: backgroundColor,', '    // Prevent the menu dropdown from being very wide due to long page titles'))
        else:
            expected = re.findall(r'Build ID: ([0-9a-f]+)', paths[2].read_text())
            ok = len(expected) == 2 and all(expected[i] in subprocess.check_output(['readelf', '-n', str(p)], timeout=5, stderr=subprocess.DEVNULL, text=True) for i, p in enumerate(paths[:2]))
        COMPATIBILITY[kind] = (signature, ok)
        return ok
    except (OSError, ValueError, KeyError, struct.error, subprocess.SubprocessError):
        return False


def ini_value(text, section, key):
    active = False
    for line in text.splitlines():
        if line.strip().startswith('['):
            active = line.strip() == '[' + section + ']'
        elif active:
            match = re.match(r'\s*' + re.escape(key) + r'\s*=\s*([^#;]+)', line)
            if match:
                return match[1].strip()
    return None


def set_ini(text, section, key, value):
    lines = text.splitlines(); start = None; end = len(lines)
    for i, line in enumerate(lines):
        if line.strip() == '[' + section + ']':
            start = i
        elif start is not None and i > start and line.strip().startswith('['):
            end = i; break
    if start is None:
        return text.rstrip() + '\n\n[' + section + ']\n' + key + '=' + value + '\n'
    for i in range(start + 1, end):
        if re.match(r'\s*' + re.escape(key) + r'\s*=', lines[i]):
            lines[i] = key + '=' + value
            return '\n'.join(lines) + '\n'
    lines.insert(start + 1, key + '=' + value)
    return '\n'.join(lines) + '\n'


def translucent(value):
    try:
        return 0 <= float(value) < 1
    except (ValueError, TypeError):
        return False


def save_changed(file, text, apply):
    if file.is_symlink():
        file = file.resolve()
        if not file.is_relative_to(HOME.resolve()):
            raise ValueError('Native config symlink leaves the user home')
    old = file.read_text() if file.exists() else ''
    if old == text:
        return False
    if not apply:
        return True
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    STATE.chmod(0o700)
    recovery = STATE / 'before' / (str(time.time_ns()) + '-' + file.name)
    recovery.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if file.exists():
        shutil.copy2(file, recovery)
    file.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.glass-', dir=file.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
        os.chmod(name, file.stat().st_mode & 0o777 if file.exists() else 0o600)
        os.replace(name, file)
    finally:
        Path(name).unlink(missing_ok=True)
    return True


def native_recipe(kind, apply):
    if kind in ('foot', 'alacritty'):
        path, sections, key, value = (
            (HOME/'.config/foot/foot.ini', ('colors-dark', 'colors-light'), 'alpha', '.62')
            if kind == 'foot' else
            (HOME/'.config/alacritty/alacritty.toml', ('window',), 'opacity', '.74'))
        text = path.read_text() if path.exists() else ''
        updated = text
        for section in sections:
            if not translucent(ini_value(updated, section, key)):
                updated = set_ini(updated, section, key, value)
        changed = save_changed(path, updated, apply)
        return ('would-configure' if changed and not apply else 'configured'), ('native background setting prepared; new windows load it' if changed else 'existing native background alpha retained')
    if kind in ('ghostty', 'kitty'):
        path = HOME/('.config/ghostty/config' if kind == 'ghostty' else '.config/kitty/kitty.conf')
        key = 'background-opacity' if kind == 'ghostty' else 'background_opacity'
        separator = ' = ' if kind == 'ghostty' else ' '
        text = path.read_text() if path.exists() else ''
        pattern = r'(?m)^\s*' + key + r'\s*(?:=\s*)?([0-9.]+)\s*(?:#.*)?$'
        match = re.search(pattern, text)
        if not match or not translucent(match[1]):
            line = key + separator + '.74'
            text = re.sub(pattern, line, text) if match else text.rstrip() + '\n' + line + '\n'
        changed = save_changed(path, text, apply)
        return ('would-configure' if changed and not apply else 'configured'), ('native background setting prepared; new windows load it' if changed else 'existing native background alpha retained')
    if kind == 'nautilus':
        source = Path(__file__).parent/'recipes/nautilus-glass.css'
        if not source.exists():
            return 'needs-theme', 'Files glass CSS recipe is missing'
        changed = save_changed(HOME/'.config/gtk-4.0/nautilus-glass.css', source.read_text(), apply)
        path = HOME/'.config/gtk-4.0/gtk.css'; text = path.read_text() if path.exists() else ''
        if 'nautilus-glass.css' not in text:
            changed = save_changed(path, '@import url("nautilus-glass.css");\n' + text, apply) or changed
        return ('would-configure' if changed and not apply else 'configured'), 'Files background CSS recipe available; GTK compositor workaround must be loaded'
    if kind in ('chatgpt', 'antigravity', 'spotify'):
        required = {
            'chatgpt': ['.local/bin/chatgpt', '.config/omarchy/glass-apps/chatgpt/build-runtime.py'],
            'antigravity': ['.local/bin/antigravity', '.config/Antigravity/daemon-glass/build-runtime.py'],
            'spotify': ['.local/bin/spotify', '.config/spicetify/Extensions/daemon-spotify-sync.js', '.config/spicetify/daemon-glass/spotify-alpha.so'],
        }[kind]
        if all((HOME/name).is_file() for name in required):
            if not compatible(kind):
                return 'needs-theme', 'installed app layout/build changed or cannot be validated; update its native glass recipe'
            return 'recipe-installed', 'native glass recipe matches installed source/build; app launch performs final validation'
        return 'needs-theme', 'install the optional native glass recipe for this app/version'
    if kind == 'screensaver':
        engine = HOME/'.local/share/omarchy-screensaver/omarchy_screensaver/modes/base.py'
        if not engine.exists() or 'background_opacity' not in engine.read_text():
            return 'needs-theme', 'Screensaver Studio 1.9 background renderer is required'
        path = HOME/'.config/omarchy-screensaver/config.toml';text = path.read_text() if path.exists() else ''
        changed = False
        if not translucent(ini_value(text, 'display', 'background_opacity')):
            changed = save_changed(path, set_ini(text, 'display', 'background_opacity', '.68'), apply)
        return ('would-configure' if changed and not apply else 'configured'), 'native screensaver background alpha retained'
    return 'needs-theme', 'no background-only recipe; request an app-specific theme patch'


def identify(value):
    value = value.lower()
    for kind, names in {
        'foot': ('foot', 'foot-server', 'footclient'), 'ghostty': ('ghostty', 'com.mitchellh.ghostty'),
        'kitty': ('kitty',), 'alacritty': ('alacritty',),
        'nautilus': ('org.gnome.nautilus', 'nautilus'),
        'chatgpt': ('chatgpt',), 'antigravity': ('antigravity',),
        'spotify': ('spotify',), 'screensaver': ('org.omarchy.screensaver', 'omarchy-screensaver', 'omarchy-screensaver-studio', 'daemon0.screensaver-studio'),
    }.items():
        if value in names:
            return kind
    return None


def desktop_apps():
    roots = [HOME/'.local/share/applications', Path('/usr/local/share/applications'), Path('/usr/share/applications'),
             HOME/'.local/share/flatpak/exports/share/applications', Path('/var/lib/flatpak/exports/share/applications')]
    apps = {}
    for root in roots:
        for file in sorted(root.glob('*.desktop')):
            identity = file.stem.lower()
            if identity in apps:
                continue
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                parser.read(file)
                entry = parser['Desktop Entry']
                if entry.get('Type', 'Application') != 'Application' or entry.get('Hidden', 'false').lower() == 'true' or entry.get('NoDisplay', 'false').lower() == 'true':
                    continue
                name = entry.get('Name', file.stem)
                startup = entry.get('StartupWMClass', '').lower()
                apps[identity] = {'name': name, 'kind': identify(identity) or identify(startup), 'class': startup}
            except (OSError, KeyError, configparser.Error, UnicodeError):
                continue
    return apps


def clients():
    signature = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
    if not signature:
        return []
    path = Path(os.environ.get('XDG_RUNTIME_DIR', '/run/user/' + str(os.getuid()))) / 'hypr' / signature / '.socket.sock'
    try:
        with socket.socket(socket.AF_UNIX) as channel:
            channel.settimeout(1);channel.connect(str(path));channel.sendall(b'j/clients')
            data = bytearray()
            while chunk := channel.recv(65536):
                data.extend(chunk)
                if len(data) > 4*1024*1024:
                    return []
        return json.loads(data)
    except (OSError, ValueError):
        return []


def notify(names):
    message = ', '.join(html.escape(name[:80]) for name in names[:5])
    if len(names) > 5:
        message += ' and ' + str(len(names)-5) + ' more'
    message += '. These apps need a background-only theme patch. Run daemon-glass status for details.'
    command = shutil.which('omarchy-notification-send') or shutil.which('notify-send')
    if not command:
        return False
    try:
        args = [command, '-t', '9000', 'Glass needs an app theme', message]
        subprocess.run(args, check=True, timeout=10, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except (OSError, subprocess.SubprocessError):
        return False


def _scan(apply=False, notifications=False):
    state_path = STATE/'status.json'
    previous = json.loads(state_path.read_text()) if state_path.exists() else {'apps': {}}
    settings_path = BASE/'universal-glass.json'
    settings = json.loads(settings_path.read_text()) if settings_path.exists() else {}
    ignored = settings.get('ignored_apps', [])
    apps = desktop_apps()
    for client in clients():
        identity = client.get('initialClass', client.get('class', '')).lower()
        if not identity:
            continue
        existing = next((key for key, value in apps.items() if identity in (key, value['class'])), None)
        if existing is None:
            apps['window:'+identity] = {'name':identity, 'kind':identify(identity), 'class':identity}
    if shutil.which('omarchy-screensaver') and not any(value['kind'] == 'screensaver' for value in apps.values()):
        apps['omarchy-screensaver'] = {'name':'Screensaver Studio', 'kind':'screensaver', 'class':'org.omarchy.screensaver'}
    records = {}; pending = []
    cache = {}
    for identity, info in sorted(apps.items()):
        if any(fnmatch.fnmatch(identity, pattern.lower()) for pattern in ignored):
            status, reason = 'ignored', 'excluded by local settings'
        else:
            kind = info['kind']
            if kind not in cache:
                try:
                    cache[kind] = native_recipe(kind, apply)
                except (OSError, ValueError) as error:
                    cache[kind] = ('needs-theme', 'native configuration could not be updated: ' + type(error).__name__)
            status, reason = cache[kind]
        old = previous.get('apps', {}).get(identity, {})
        record = {'name':info['name'], 'status':status, 'reason':reason, 'notified':old.get('notified', False)}
        if status == 'needs-theme' and not record['notified']:
            pending.append(identity)
        if status != 'needs-theme':
            record['notified'] = False
        records[identity] = record
    if notifications and pending and notify([records[key]['name'] for key in pending]):
        for key in pending:
            records[key]['notified'] = True
    report = {'schema':1, 'checked_at':time.time(), 'apps':records,
              'scope':'Recipe/configuration status, not proof of visible alpha in arbitrary apps.'}
    if apply or notifications:
        STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
        STATE.chmod(0o700)
        fd, temporary = tempfile.mkstemp(prefix='.status-', dir=STATE)
        with os.fdopen(fd, 'w') as stream:
            json.dump(report, stream, indent=2);stream.write('\n')
        os.replace(temporary, state_path)
    return report


def scan(apply=False, notifications=False):
    if not apply and not notifications:
        return _scan(False, False)
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    STATE.chmod(0o700)
    with (STATE/'scan.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        return _scan(apply, notifications)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['scan', 'watch', 'status'])
    parser.add_argument('--apply', action='store_true', help='write supported native background settings with recovery copies')
    parser.add_argument('--notify', action='store_true', help='notify once per app needing a theme; initial inventory is one batch')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    if args.command == 'watch':
        while True:
            try:
                scan(apply=True, notifications=True)
            except (OSError, ValueError) as error:
                print('Glass scan deferred:', type(error).__name__, flush=True)
            time.sleep(20)
    else:
        report = scan(args.apply if args.command == 'scan' else False, args.notify)
        if args.json:
            print(json.dumps(report, indent=2))
        else:
            for record in report['apps'].values():
                print(record['status'] + ': ' + record['name'] + ' — ' + record['reason'])


if __name__ == '__main__':
    main()
