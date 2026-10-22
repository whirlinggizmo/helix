"""SDL3 for the SDL3 backends (sdl3-gl, sdl3-gpu): the library a native build links, found or made into build/deps the first time. The headers are always
vendor/sdl3's, SDL 3.4.18's (dependencies.json, sdl3), so a build never uses an API newer than the pin, whichever library it links.

- Linux: the system's SDL3 when pkg-config finds one of 3.4.18 or newer (SDL keeps its ABI across 3.x); else the pinned source release,
  checked, built once with CMake into build/deps as a static library. CMake is needed for that build alone.
- Windows: the pinned official SDL3-devel VC release, checked, unpacked into build/deps; its DLL goes beside each program.
- macOS: the pinned official disk image's SDL3.xcframework, checked, copied into build/deps; its framework goes beside each program.

    python3 tools/sdl3.py      # finds or builds it, and says which

    import sdl3
    sdl3.find()   # an Sdl3: the library to link, what goes beside the program, and where it came from

Standard library only."""
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPS = ROOT / 'build' / 'deps'


class Sdl3:
    """What a build needs of SDL3: the library to link (a path), the files a program needs beside it (none when the system provides them),
    and where it came from, for the build to say."""

    def __init__(self, library, runtime, origin):
        self.library = library
        self.runtime = runtime
        self.origin = origin


def pin():
    """dependencies.json's sdl3 entry."""
    return json.loads((ROOT / 'dependencies.json').read_text(encoding='utf-8'))['sdl3']


def check_headers():
    """vendor/sdl3 is the pinned release's include/SDL3 and license: one SHA-256 over each file's path and SHA-256, in path order."""
    headers = pin()['headers']
    directory = ROOT / headers['directory']
    digest = hashlib.sha256()
    for file in sorted(p for p in directory.rglob('*') if p.is_file()):
        digest.update(file.relative_to(directory).as_posix().encode() + b'\0' + hashlib.sha256(file.read_bytes()).hexdigest().encode() + b'\n')
    if digest.hexdigest() != headers['treeSha256']:
        raise RuntimeError(f'vendor/sdl3 differs from its pin in dependencies.json: {digest.hexdigest()}')


def fetch(entry):
    """A pinned archive (SDL's, or another build/deps tool's), downloaded into build/deps and checked against its SHA-256; never kept when it
    differs."""
    DEPS.mkdir(parents=True, exist_ok=True)
    archive = DEPS / entry['url'].rsplit('/', 1)[1]
    if not archive.is_file() or hashlib.sha256(archive.read_bytes()).hexdigest() != entry['sha256']:
        print(f'build/deps: downloading {entry["url"]}', flush=True)
        partial = archive.with_name(archive.name + '.part')
        with urllib.request.urlopen(entry['url'], timeout=300) as response:
            partial.write_bytes(response.read())
        digest = hashlib.sha256(partial.read_bytes()).hexdigest()
        if digest != entry['sha256']:
            partial.unlink()
            raise RuntimeError(f'build/deps: {entry["url"]} has SHA-256 {digest}, not the pinned {entry["sha256"]}')
        partial.replace(archive)
    return archive


def version_at_least(found, minimum):
    """Whether dotted version found is minimum or newer."""
    def parts(v):
        return tuple(int(x) for x in v.split('.')[:3])
    return parts(found) >= parts(minimum)


def system_linux(minimum):
    """The system's SDL3 when pkg-config finds one of minimum or newer, else None."""
    try:
        version = subprocess.check_output(['pkg-config', '--modversion', 'sdl3'], text=True, stderr=subprocess.DEVNULL).strip()
        if not version_at_least(version, minimum):
            return None
        libdir = subprocess.check_output(['pkg-config', '--variable=libdir', 'sdl3'], text=True).strip()
    except (OSError, subprocess.CalledProcessError, ValueError):
        return None
    library = Path(libdir) / 'libSDL3.so'
    if not library.exists():
        return None
    return Sdl3(str(library), [], f'the system\'s SDL {version} ({library})')


# What building SDL needs on Linux, beyond a C compiler: CMake and the development headers of the parts SDL loads at run time (X11, Wayland,
# audio, D-Bus, udev). Debian/Ubuntu's is CI's list (SDL3_BUILD in .github/workflows/ci.yml); Fedora's the same parts, after SDL's
# docs/README-linux.md, which lists other distributions'.
PACKAGES = {
    'Debian/Ubuntu': 'sudo apt-get install cmake libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev '
                     'libxkbcommon-dev libwayland-dev wayland-protocols libdecor-0-dev libasound2-dev libpulse-dev libpipewire-0.3-dev libdbus-1-dev '
                     'libudev-dev libdrm-dev libgbm-dev libegl-dev',
    'Fedora': 'sudo dnf install cmake libX11-devel libXext-devel libXrandr-devel libXcursor-devel libXfixes-devel libXi-devel libXScrnSaver-devel '
              'libXtst-devel libxkbcommon-devel wayland-devel wayland-protocols-devel libdecor-devel alsa-lib-devel pulseaudio-libs-devel '
              'pipewire-devel dbus-devel systemd-devel libdrm-devel mesa-libgbm-devel mesa-libEGL-devel',
}


def install_hint():
    """The commands that install what building SDL needs, a line each."""
    return '\n'.join(f'  {name}: {command}' for name, command in PACKAGES.items()) + '\n  (others: SDL\'s docs/README-linux.md)'


def backends(configure_output):
    """SDL's configure summary's enabled backends, by kind ("Video drivers", "Audio drivers", ...): names, without "(dynamic)"."""
    found = {}
    for line in configure_output.splitlines():
        line = line.removeprefix('--').strip()
        kind, colon, names = line.partition(':')
        if colon and kind.endswith(('drivers', 'libraries')):
            found[kind] = {name.split('(')[0] for name in names.split()}
    return found


def check_backends(found, prefix):
    """Stops when SDL found no windowing system to build for (its program could open no window); warns, naming the packages, for the
    optional parts it left out (prefix: where the build goes, deleted to build again)."""
    video, audio = found.get('Video drivers', set()), found.get('Audio drivers', set())
    if not video & {'x11', 'wayland'}:
        raise RuntimeError('sdl3: SDL found neither X11\'s nor Wayland\'s development headers, so it could open no window. Install them and '
                           'build again:\n' + install_hint())
    missing = [part for part, name in (('Wayland', 'wayland' in video), ('X11', 'x11' in video), ('PipeWire', 'pipewire' in audio),
                                       ('PulseAudio', 'pulseaudio' in audio), ('ALSA', 'alsa' in audio)) if not name]
    if missing:
        print(f'sdl3: building without {", ".join(missing)} (their development headers weren\'t found); to have them, install these and delete '
              f'{prefix.relative_to(ROOT).as_posix()}:\n' + install_hint(), flush=True)


def built_linux(entry, version):
    """The pinned source release built once into build/deps/<directory>-static: a static library (SDL loads X11, Wayland and the audio
    libraries at run time, so it links only libm and pthread besides)."""
    prefix = DEPS / (entry['directory'] + '-static')
    pc = prefix / 'lib' / 'pkgconfig' / 'sdl3.pc'
    if not pc.is_file():
        if shutil.which('cmake') is None:
            raise RuntimeError(f'sdl3: no system SDL3 of {entry["systemMinimum"]} or newer, and building the pinned one (once) needs CMake and '
                               'the development headers of what SDL uses:\n' + install_hint())
        archive = fetch(entry)
        source = DEPS / entry['directory']
        shutil.rmtree(source, ignore_errors=True)
        with tarfile.open(archive) as tar:
            tar.extractall(DEPS, filter='data')
        build = DEPS / (entry['directory'] + '-build')
        shutil.rmtree(build, ignore_errors=True)
        print(f'sdl3: building SDL {version} into {prefix.relative_to(ROOT)} (once)', flush=True)
        configured = subprocess.run(['cmake', '-S', source, '-B', build, '-DCMAKE_BUILD_TYPE=Release', f'-DCMAKE_INSTALL_PREFIX={prefix}',
                                     '-DCMAKE_INSTALL_LIBDIR=lib', '-DCMAKE_POSITION_INDEPENDENT_CODE=ON', '-DSDL_SHARED=OFF', '-DSDL_STATIC=ON',
                                     '-DSDL_TEST_LIBRARY=OFF', '-DSDL_TESTS=OFF', '-DSDL_EXAMPLES=OFF', '-DSDL_INSTALL_DOCS=OFF'],
                                    capture_output=True, text=True, encoding='utf-8')
        print(configured.stdout, configured.stderr, sep='', flush=True)
        if configured.returncode != 0:
            raise RuntimeError('sdl3: configuring SDL failed (above)')
        check_backends(backends(configured.stdout), prefix)
        subprocess.run(['cmake', '--build', build, '--parallel', str(os.cpu_count() or 4)], check=True)
        subprocess.run(['cmake', '--install', build], check=True)
        shutil.rmtree(build)
        shutil.rmtree(source)
    return Sdl3(str(prefix / 'lib' / 'libSDL3.a'), [], f'SDL {version} built from its pinned source ({prefix.relative_to(ROOT).as_posix()})')


def windows(entry, version):
    """The pinned SDL3-devel VC release unpacked into build/deps: its import library to link, its DLL beside the program."""
    directory = DEPS / entry['directory']
    arch = 'arm64' if platform.machine().lower() in ('arm64', 'aarch64') else 'x64'
    lib = directory / 'lib' / arch
    if not (lib / 'SDL3.lib').is_file():
        with zipfile.ZipFile(fetch(entry)) as z:
            z.extractall(DEPS)
    return Sdl3(str(lib / 'SDL3.lib'), [lib / 'SDL3.dll'], f'SDL {version}, the pinned official Windows release')


def macos(entry, version):
    """The pinned disk image's SDL3.xcframework copied into build/deps: its macOS framework's library linked (found at run time through
    the program's rpath, its own directory), and the framework beside the program."""
    directory = DEPS / entry['directory']
    xcframework = directory / 'SDL3.xcframework'
    if not xcframework.is_dir():
        image = fetch(entry)
        mount = DEPS / 'sdl3-dmg'
        mount.mkdir(parents=True, exist_ok=True)
        subprocess.run(['hdiutil', 'attach', '-nobrowse', '-readonly', '-mountpoint', mount, image], check=True)
        try:
            shutil.rmtree(directory, ignore_errors=True)
            directory.mkdir(parents=True)
            shutil.copytree(mount / 'SDL3.xcframework', xcframework, symlinks=True)
        finally:
            subprocess.run(['hdiutil', 'detach', mount], check=True)
    frameworks = xcframework / 'macos-arm64_x86_64'
    return Sdl3(str(frameworks / 'SDL3.framework' / 'SDL3'), [frameworks / 'SDL3.framework'], f'SDL {version}, the pinned official macOS release')


def find():
    """The SDL3 to link on this system, found or made into build/deps the first time."""
    check_headers()
    entries = pin()
    if sys.platform == 'win32':
        return windows(entries['windows'], entries['version'])
    if sys.platform == 'darwin':
        return macos(entries['macos'], entries['version'])
    return system_linux(entries['linux']['systemMinimum']) or built_linux(entries['linux'], entries['version'])


if __name__ == '__main__':
    import cli
    cli.parser(__doc__).parse_args()
    found = find()
    print(f'sdl3: {found.origin}')
    print(f'sdl3: link {found.library}')
    for file in found.runtime:
        print(f'sdl3: beside the program: {file}')
