"""A build's name and its folders (docs/CONVENTIONS.md, Build).

A build is named `<platform>-<config>-<backend>[-<option>...][-<sanitizer>]`:

- platform: what the program links against, this machine's for a native build (`linux-x64`, `linux-arm64`, `macos-arm64`, `macos-x64`,
  `windows-x64-msvc`, or `windows-x64-mingw` when hxcpp is told MinGW), and `js` for the browser's;
- config: `debug` or `release`;
- backend: the API the build draws with, always named: `webgl2` (js), `sokol-gl`, `sdl3-gl`, `sdl3-gpu` (native);
- options, in this order, each only adding: `dev`, the dev loop's page with hot reload built in (tools/example.py dev makes it, no build
  does); no sanitizer exists yet.

What a build makes goes to out/<platform>/<config>-<backend>[-<option>...]/: natively bin/<example>/ (the program, named for its example,
and what it loads beside it) with bin/assets beside the examples' folders, in the browser site/<example>/ with site/assets, so an example
loads ../assets either way and bin/ or site/ is what ships. Its scratch (the HXML, hxcpp's generated C++ and objects, the record of whose
assets are whose) is in build/<name>/. Deleting out/ is a clean."""
import os
from pathlib import Path
import platform as host
import sys

ROOT = Path(__file__).resolve().parents[1]
CONFIGS = ('debug', 'release')
# Each backend's target: the browser's (js) or native.
BACKENDS = {'webgl2': 'js', 'sokol-gl': 'native', 'sdl3-gl': 'native', 'sdl3-gpu': 'native'}
# Every option, in the order a name gives them.
OPTIONS = ('dev',)
PLATFORMS = ('linux-x64', 'linux-arm64', 'macos-arm64', 'macos-x64', 'windows-x64-msvc', 'windows-x64-mingw', 'js')


def machine():
    """This machine's native platform: what a native build here links against."""
    arm = host.machine().lower() in ('arm64', 'aarch64')
    if sys.platform == 'win32':
        return 'windows-x64-mingw' if os.environ.get('HXCPP_MINGW') else 'windows-x64-msvc'
    if sys.platform == 'darwin':
        return 'macos-arm64' if arm else 'macos-x64'
    return 'linux-arm64' if arm else 'linux-x64'


class Build:
    """One build: its platform, config, backend and options, its name and folders."""

    def __init__(self, platform, config, backend, options=()):
        self.platform, self.config, self.backend, self.options = platform, config, backend, tuple(options)

    @property
    def web(self):
        """Whether it's the browser's build."""
        return BACKENDS[self.backend] == 'js'

    @property
    def debug(self):
        """Whether it's a debug build."""
        return self.config == 'debug'

    @property
    def variant(self):
        """The name without its platform: `<config>-<backend>[-<option>...]`, its folder under out/<platform>/."""
        return '-'.join((self.config, self.backend) + self.options)

    @property
    def name(self):
        """The whole name."""
        return f'{self.platform}-{self.variant}'

    @property
    def out(self):
        """Where its results go: out/<platform>/<variant>."""
        return ROOT / 'out' / self.platform / self.variant

    @property
    def programs(self):
        """The folder of its examples' folders, beside their shared assets: bin/ natively, site/ in the browser."""
        return self.out / ('site' if self.web else 'bin')

    @property
    def assets(self):
        """The examples' shared assets, which each loads as ../assets."""
        return self.programs / 'assets'

    @property
    def scratch(self):
        """Its working files: build/<name>."""
        return ROOT / 'build' / self.name

    def __str__(self):
        return self.name


def js_or_machine(backend):
    """The platform a backend's build has here: js for the browser's, this machine's for a native one."""
    return 'js' if BACKENDS[backend] == 'js' else machine()


def parse(text, options=()):
    """A build from `<config>-<backend>[-<option>...]` or a whole name, its platform this machine's (js for the browser's); options are
    those allowed here. Raises ValueError, saying why, for a name that isn't one or a platform this machine can't build."""
    rest = text
    named = next((p for p in sorted(PLATFORMS, key=len, reverse=True) if rest.startswith(p + '-')), None)
    if named:
        rest = rest[len(named) + 1:]
    config, _, rest = rest.partition('-')
    if config not in CONFIGS:
        raise ValueError(f'{text}: a build is [<platform>-]<config>-<backend>[-<option>...], the config one of {", ".join(CONFIGS)}')
    backend = next((b for b in sorted(BACKENDS, key=len, reverse=True) if rest == b or rest.startswith(b + '-')), None)
    if backend is None:
        raise ValueError(f'{text}: the backend is one of {", ".join(BACKENDS)}')
    given = [o for o in rest[len(backend):].split('-') if o]
    for option in given:
        if option not in options:
            raise ValueError(f'{text}: {option} isn\'t an option here' + (f' (here: {", ".join(options)})' if options else ''))
    if given != sorted(given, key=OPTIONS.index):
        raise ValueError(f'{text}: options go in the order {", ".join(OPTIONS)}')
    platform = js_or_machine(backend)
    if named and named != platform:
        raise ValueError(f'{text}: this machine builds {backend} for {platform}, not {named}')
    return Build(platform, config, backend, given)
