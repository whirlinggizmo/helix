"""sokol-shdc, the shader compiler: the sokol-tools-bin build dependencies.json pins (sokolToolsBin), for this system, downloaded into the
user's cache the first time and checked against its SHA-256 below every time it's used. From floooh's repository, or the Whirling Gizmo
mirror when that can't be reached. To move to a newer build, change the pin, HASHES_PIN and the hashes together (wgrender-c's tools/shdc.py,
whose hashes these are).

    import shdc
    subprocess.run([shdc.path(), '-i', 'x.glsl', ...])

Standard library only."""
import hashlib
import json
import os
import platform
import stat
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ('floooh/sokol-tools-bin', 'whirlinggizmo/sokol-tools-bin')
HASHES_PIN = '11d0cf678105d614d675e6d9bd2aaf3eeff12f8c'
# Each system's folder in sokol-tools-bin's bin/, and its program's SHA-256.
SHA256 = {
    'linux': 'ed35e89ef381d521a499096ed4ada85e4d135d8011e151cca6b7d893c43b21df',
    'linux_arm64': '446b4bcea0c81d3ae529bc0d93533ea661b017f5b9ec2b2293a4c85f5fdcb639',
    'osx': '8b4a6ac1172ec0d90dd41d611067d5e87a51e78dc28acb216cfc341d880b1d78',
    'osx_arm64': '92db37975ad7ff3c3c9bc27cba1503287377cb287ebabf60d1c6b597abfa3244',
    'win32': 'bd616287f9ea689d53c6d260e443ee733e61ae1b73a9b37adc482ead0364d561',
}


def cache():
    """The user's cache for HeliX's tools: %LOCALAPPDATA%, ~/Library/Caches or $XDG_CACHE_HOME (~/.cache)."""
    if sys.platform == 'win32':
        base = Path(os.environ.get('LOCALAPPDATA') or Path.home() / 'AppData/Local')
    elif sys.platform == 'darwin':
        base = Path.home() / 'Library/Caches'
    else:
        base = Path(os.environ.get('XDG_CACHE_HOME') or Path.home() / '.cache')
    return base / 'helix' / 'tools'


def path():
    """The pinned sokol-shdc, fetched the first time and checked every time."""
    pin = json.loads((ROOT / 'dependencies.json').read_text(encoding='utf-8'))['sokolToolsBin']
    if pin != HASHES_PIN:
        sys.exit(f'shdc: dependencies.json pins sokol-tools-bin {pin}, but tools/shdc.py has the hashes of {HASHES_PIN}')
    system, machine = platform.system(), platform.machine().lower()
    folder = {'Linux': 'linux_arm64' if machine in ('aarch64', 'arm64') else 'linux',
              'Darwin': 'osx_arm64' if machine == 'arm64' else 'osx', 'Windows': 'win32'}[system]
    exe = 'sokol-shdc.exe' if system == 'Windows' else 'sokol-shdc'
    found = cache() / f'sokol-shdc-{pin[:12]}' / exe
    if found.exists() and hashlib.sha256(found.read_bytes()).hexdigest() == SHA256[folder]:
        return found
    found.parent.mkdir(parents=True, exist_ok=True)
    data, failures = None, []
    for source in SOURCES:
        url = f'https://raw.githubusercontent.com/{source}/{pin}/bin/{folder}/{exe}'
        print(f'shdc: downloading {url}', flush=True)
        try:
            with urllib.request.urlopen(url, timeout=120) as response:
                fetched = response.read()
        except OSError as e:
            failures.append(f'{url}: {e}')
            continue
        digest = hashlib.sha256(fetched).hexdigest()
        # Never used, wherever it came from, unless it's the pinned one.
        if digest != SHA256[folder]:
            failures.append(f'{url}: SHA-256 {digest}, not the pinned {SHA256[folder]}')
            continue
        data = fetched
        break
    if data is None:
        sys.exit('shdc: no source gave the pinned sokol-shdc:\n  ' + '\n  '.join(failures))
    # Put in place only once it's whole.
    partial = found.with_name(found.name + '.part')
    partial.write_bytes(data)
    if os.name != 'nt':
        partial.chmod(partial.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    partial.replace(found)
    return found
