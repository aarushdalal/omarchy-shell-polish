#!/usr/bin/env python3
"""Preview or install user-owned desktop overlays with an exact rollback journal."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def apply_files(operations, state):
    state.mkdir(parents=True, exist_ok=False, mode=0o700)
    journal = []
    try:
        for number, (destination, payload, mode) in enumerate(operations):
            if destination.is_symlink(): raise ValueError('Refusing to overwrite a symlink: ' + str(destination))
            old = state/'files'/str(number) if destination.exists() else None
            if old:
                old.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(destination, old)
            entry = {'target': str(destination), 'previous': str(old) if old else None,
                     'installed_hash': hashlib.sha256(payload).hexdigest(), 'mode': mode}
            journal.append(entry)
            (state/'journal.json').write_text(json.dumps(journal, indent=2))
            destination.parent.mkdir(parents=True, exist_ok=True)
            fd, temporary = tempfile.mkstemp(prefix='.refinement-', dir=destination.parent)
            try:
                with os.fdopen(fd, 'wb') as stream:
                    stream.write(payload); stream.flush(); os.fsync(stream.fileno())
                os.chmod(temporary, mode); os.replace(temporary, destination)
            finally: Path(temporary).unlink(missing_ok=True)
    except Exception:
        rollback(state, force=True)
        raise
    return journal

def rollback(state, force=False):
    entries = json.loads((state/'journal.json').read_text())
    skipped = []
    for entry in reversed(entries):
        target = Path(entry['target'])
        if target.is_symlink() or (not force and target.exists() and sha(target) != entry['installed_hash']):
            skipped.append(str(target)); continue
        if entry['previous']:
            target.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(entry['previous'], target)
        else: target.unlink(missing_ok=True)
    if skipped: print('Preserved files changed after installation:', *skipped, sep='\n')

def plan():
    config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home()/'.config')))
    operations = []
    shell_config = config/'omarchy/shell.json'
    if shell_config.is_file():
        data = json.loads(shell_config.read_text())
        names = {f'omarchy.{name}': f'community.{name}' for name in ('network', 'bluetooth', 'audio', 'power', 'monitor', 'menu')}
        for source in sorted((ROOT/'plugins').rglob('*'), key=lambda path: path.name == 'manifest.json'):
            if source.is_file(): operations.append((config/'omarchy/plugins'/source.relative_to(ROOT/'plugins'), source.read_bytes(), 0o644))
        sections = data.setdefault('bar', {}).setdefault('layout', {})
        for entries in sections.values():
            for entry in entries:
                if isinstance(entry, dict) and entry.get('id') in names: entry['id'] = names[entry['id']]
        right = sections.setdefault('right', [])
        if not any(entry.get('id') == 'community.session' for entry in right): right.append({'id': 'community.session'})
        enabled = data.setdefault('plugins', [])
        enabled[:] = [{'id': entry} if isinstance(entry, str) else entry for entry in enabled]
        for identifier in [*names.values(), 'community.session', 'community.osd', 'community.notifications']:
            if not any((entry if isinstance(entry, str) else entry.get('id')) == identifier for entry in enabled): enabled.append({'id': identifier})
        disabled = data.setdefault('disabledPlugins', [])
        restores = data.setdefault('cloneSourceRestores', [])
        for native_id in ['omarchy.menu', 'omarchy.osd', 'omarchy.notifications']:
            if native_id not in disabled: disabled.append(native_id)
            clone = native_id.replace('omarchy.', 'community.')
            if clone not in restores: restores.append(clone)
        operations.append((shell_config, (json.dumps(data, indent=2)+'\n').encode(), shell_config.stat().st_mode & 0o777))
    caelestia = config/'quickshell/caelestia'
    if (caelestia/'shell.qml').is_file():
        for source in (ROOT/'caelestia').rglob('*.qml'):
            operations.append((caelestia/source.relative_to(ROOT/'caelestia'), source.read_bytes(), 0o644))
    daemon_config = config/'caelestia/shell.json'
    if daemon_config.is_file():
        data = json.loads(daemon_config.read_text())
        data.setdefault('session', {}).setdefault('commands', {})['logout'] = ['multienv-logout']
        operations.append((daemon_config, (json.dumps(data, indent=2)+'\n').encode(), daemon_config.stat().st_mode & 0o777))
    return operations

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--rollback', type=Path)
    args = parser.parse_args()
    if args.rollback:
        rollback(args.rollback); return
    operations = plan()
    for destination, _, _ in operations: print('Install:' if args.apply else 'Would install:', destination)
    if args.apply:
        state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home()/'.local/state')))/'desktop-refinement'/str(time.time_ns())
        apply_files(operations, state)
        print('Recovery journal:', state)
        print('Omarchy plugins hot-reload; DaemonOS reads its overlay on its next session. Install the motion selector and multienv-logout separately.')

if __name__ == '__main__': main()
