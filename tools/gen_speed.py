#!/usr/bin/env python3
"""helix-raylib's speed and size against raylib C, Godot, three.js, Lime and helix-legacy on the same two programs, written for each in
tools/speed/contenders/<name>/: raylib's textures_bunnymark (bunnies of one texture bouncing in an 800 x 450 window) and its
models_animation many at once (the robots: a grid of robot.glb, each posed at its own frame, in 1280 x 720). It makes docs/speed.json and
docs/benchmarks.md's speed tables and charts (docs/benchmarks/*.svg). It runs when asked, never in CI: a run takes minutes to hours.

    python3 tools/gen_speed.py [--native | --page] [--headless | --headed] [--backend vulkan|gl] [--all] [--runs 3] [--browser PATH]
                               [--write] [--unchecked] [--no-control] [bunnymark] [robots] [CONTENDER ...]

The programs are bunnymark and robots, both when none is named. The contenders are helix-raylib, raylib-c, godot, three, lime (the
bunnymark alone) and helix-legacy. With none named, a run takes helix-raylib, raylib C as the control (not with --no-control), and each
other contender whose rows are missing or were measured at another version than dependencies.json's speed entry pins; --all takes every
contender, and the pages over both backends. Each is built into build/speed/<contender>/ under build/.lock, with the assets taken from raylib's own release
(the bunny's texture, the robot). A contender whose toolchain this machine lacks is skipped with one line saying so: raylib-c's page
needs Emscripten (EMSDK, or HELIX_EMSDK, or ~/toolchains/emsdk), godot needs its binary (HELIX_GODOT, or godot on PATH, or
~/toolchains/godot/Godot_v<version>-stable_linux.x86_64), three needs npm (and installs three.js, esbuild and, for its desktop program,
Electron), lime needs Lime installed in the user's haxelib at the pinned version (its own BunnyMark demo's renderer), helix-legacy needs
helix-legacy's checkout (HELIX_LEGACY, or ../helix-legacy beside this one).

--page runs the pages (in Chromium with its frame rate cap lifted, on ANGLE over Vulkan, or over GL with --backend gl) and --native the
native programs (one at a time, with vsync off), three.js's in Electron; neither flag runs both. --headless, the default, runs them off
screen (the native programs on a private display with software GL, whose times aren't representative; the pages in headless Chromium);
--headed runs the native programs in windows on $DISPLAY, and the pages over GL in the browser's (over Vulkan a visible window loses its
WebGL context at startup, so those stay headless). Every program spawns from the same seed. Each count draws 120 frames to warm up and
times 600: the mean and the 95th percentile frame time, the median over --runs of each. ramp starts at 1000 and adds 1000 every 60
frames while those averaged 59 frames a second or better: the most held. The bunnymark's counts are 10k, 50k, 100k, 150k and 200k and
ramp, the robots' 50, 200 and 400. Every run is a JSON line in build/speed/runs/<stamp>.jsonl.

--write puts the run's medians, sizes, versions, date and machine into docs/speed.json, replacing the rows of the contenders it ran and
leaving the others, and remakes docs/benchmarks.md's speed tables between their markers and the charts: a row measured on another date
than the table's newest says so. Before it times anything, the machine must be quiet: a load average of QUIET_LOAD at most, and a pinned
loop within QUIET_LOOP_SECONDS. After, the control must be within CONTROL_DRIFT of its last rows; native times are written from --headed
runs alone, and with the control in the run. --unchecked skips the checks. A page's size is every file it fetched but the assets (gzip and brotli too, where the
brotli tool is there); three's is also its page bundled and minified with esbuild, the size a three.js game ships. A native program's
size is its binary stripped, and Electron's its files as installed with the page bundled.

Linux only. Standard library only."""
import gzip
import json
import os
import shutil
import statistics
import subprocess
import sys
import time
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
HERE = TOOLS / 'speed'
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))
import cli  # noqa: E402

# The checkout's build lock is Unix's advisory lock; Windows has none here, and the measurements aren't made there.
try:
    import fcntl
except ImportError:  # Windows
    fcntl = None

CONTENDERS_DIR = HERE / 'contenders'
OUT = ROOT / 'build/speed'
LOCK = ROOT / 'build/.lock'
STORE = ROOT / 'docs/speed.json'
PAGE = ROOT / 'docs/benchmarks.md'
PROGRAMS = ['bunnymark', 'robots']
CONTENDERS = ['helix-raylib', 'raylib-c', 'godot', 'three', 'lime', 'helix-legacy']
BUNNY_COUNTS = [10000, 50000, 100000, 150000, 200000]
ROBOT_COUNTS = [50, 200, 400]
# A page's run: seconds before it is given up; native runs the same.
PAGE_SECONDS = {'count': 600, 'ramp': 1500}
NATIVE_SECONDS = {'count': 180, 'ramp': 900}
# Files a page fetches that aren't its code: the assets each program loads.
ASSET_SUFFIXES = ('.png', '.glb', '.data', '.pck', '.ico')
RAYLIB = '5.5'
# One file fetched by helix-legacy's page that is its code, under a name the suffix rule would count out.
GODOT_PRESETS = {'linux': 'Linux', 'web': 'Web'}
# Electron's binary, installed beside three.js (build_three).
ELECTRON = OUT / 'three/npm/node_modules/electron/dist/electron'
# Where each contender runs: the rows it can have.
WHERES = {'helix-raylib': ['page-vulkan', 'page-gl', 'native-gl', 'native-sdlgpu'], 'raylib-c': ['page-vulkan', 'page-gl', 'native-gl'],
          'godot': ['page-vulkan', 'page-gl', 'native-gl', 'native-vulkan'], 'three': ['page-vulkan', 'page-gl', 'native-electron'],
          'lime': ['page-vulkan', 'page-gl'], 'helix-legacy': ['page-vulkan', 'page-gl']}
# The quiet machine timing needs: the 1-minute load average at most, and a pinned loop of 20 million additions in Python within so many
# seconds (0.83 on coinspinner; a CPU its firmware clamps takes 0.9 and up, docs/benchmarks.md).
QUIET_LOAD = 2.0
QUIET_LOOP_SECONDS = 0.9
# How far the control (raylib C) may move from its last rows, as the median ratio over its counts, before a run isn't written.
CONTROL_DRIFT = 0.2


def pins():
    """dependencies.json's speed entry: the versions of three.js, esbuild, Electron, Godot and Lime."""
    return json.loads((ROOT / 'dependencies.json').read_text(encoding='utf-8'))['speed']


def say(text):
    print(f'gen_speed: {text}', flush=True)


def run(arguments, cwd=None, env=None, timeout=None):
    """Runs a command; its output, or a SystemExit saying what failed."""
    done = subprocess.run([str(a) for a in arguments], cwd=cwd, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace',
                          timeout=timeout)
    if done.returncode:
        raise SystemExit(f'gen_speed: {" ".join(str(a) for a in arguments[:3])}... failed\n{(done.stdout + done.stderr)[-3000:]}')
    return done.stdout


# ---- Toolchains ----


def emsdk_env():
    """The environment Emscripten's emsdk_env.sh sets, or None without it."""
    home = os.environ.get('HELIX_EMSDK') or os.environ.get('EMSDK') or str(Path.home() / 'toolchains/emsdk')
    script = Path(home) / 'emsdk_env.sh'
    if not script.is_file():
        return None
    printed = subprocess.run(['bash', '-c', f'source "{script}" >/dev/null 2>&1 && env -0'], capture_output=True)
    if printed.returncode:
        return None
    env = dict(line.split('=', 1) for line in printed.stdout.decode('utf-8', 'replace').split('\0') if '=' in line)
    return env if shutil.which('emcc', path=env.get('PATH', '')) else None


def godot_binary():
    """Godot's binary, or None."""
    named = os.environ.get('HELIX_GODOT')
    if named and Path(named).is_file():
        return Path(named)
    on_path = shutil.which('godot')
    if on_path:
        return Path(on_path)
    guess = Path.home() / 'toolchains/godot' / f'Godot_v{pins()["godot"]}-stable_linux.x86_64'
    return guess if guess.is_file() else None


def legacy_checkout():
    """helix-legacy's checkout, or None."""
    named = Path(os.environ.get('HELIX_LEGACY') or ROOT.parent / 'helix-legacy')
    return named if (named / 'tools/example.py').is_file() else None


def raylib_source():
    """raylib's source for its pinned release, built, from tools/raylib_parity.py."""
    import raylib_parity
    return raylib_parity.raylib(RAYLIB)


# ---- Building ----


def haxe(arguments, env):
    run(['haxe', *arguments], cwd=ROOT, env=env)


def write_page(directory, title, width, height):
    """A page that runs app.js in a canvas of width x height."""
    directory.mkdir(parents=True, exist_ok=True)
    (directory / 'index.html').write_text(
        f'<!doctype html><html lang="en"><meta charset="utf-8"><title>{title}</title><link rel="icon" href="data:,">'
        f'<style>html,body{{margin:0;background:#1a1d26;overflow:hidden}}canvas{{display:block;width:{width}px;height:{height}px}}</style>'
        '<canvas id="canvas"></canvas><script src="app.js"></script></html>\n', encoding='utf-8')


def build_helix_raylib(programs, page, native):
    """helix-raylib's programs: a page (release, unminified, as tools/gen_sizes.py builds) and natively for GL and SDL_GPU."""
    import native_build
    import pins as repo_pins
    import sdl3
    repo_pins.use_haxelib()
    if native:
        repo_pins.check_hxcpp()
    env = native_build.env(sdl3.find() if native else None)
    jobs = f'HXCPP_COMPILE_THREADS={os.cpu_count() or 4}'
    source = raylib_source()
    assets = {'bunnymark': [source / 'examples/textures/resources/wabbit_alpha.png'], 'robots': [source / 'examples/models/resources/models/gltf/robot.glb']}
    sizes = {'bunnymark': (800, 450), 'robots': (1280, 720)}
    for program in programs:
        home = OUT / 'helix-raylib' / program
        common = ['-lib', 'helix-raylib', '-cp', CONTENDERS_DIR / 'helix-raylib' / program, '-main', 'Main', '-D', 'helix-company=helix',
                  '-D', f'helix-product=speed-{program}', '-dce', 'full', '-D', 'analyzer-optimize', '-D', 'helix-raylib-portable-sys']
        if page:
            say(f'building helix-raylib {program} page')
            web = home / 'web'
            write_page(web, f'helix-raylib {program}', *sizes[program])
            haxe(common + ['-js', web / 'app.js'], env)
            for asset in assets[program]:
                shutil.copy(asset, web / asset.name)
        if native:
            # A native helix-raylib program reads its files from ../web beside its directory (Runtime.root), as the examples are laid out, so
            # the assets go there too, whether or not the page was built.
            (home / 'web').mkdir(parents=True, exist_ok=True)
            for asset in assets[program]:
                shutil.copy(asset, home / 'web' / asset.name)
            for backend, defines in (('native-gl', []), ('native-sdlgpu', ['-D', 'sdl_gpu'])):
                say(f'building helix-raylib {program} {backend}')
                haxe(common + defines + ['-D', jobs, '-cpp', home / backend], env)


def build_raylib_c(programs, page, native):
    """raylib's own C programs: natively against the release's libraylib.a (its default -O1, the program -O2), and with Emscripten -O3 as
    raylib's web build is (WebGL1). Skipped for the page without Emscripten."""
    import raylib_parity
    source = raylib_source()
    here = CONTENDERS_DIR / 'raylib-c'
    emsdk = emsdk_env() if page else None
    if page and emsdk is None:
        say('raylib-c page skipped: no Emscripten (EMSDK, HELIX_EMSDK or ~/toolchains/emsdk)')
    if page and emsdk is not None:
        web_lib = OUT / 'raylib-c/web-lib'
        if not (web_lib / 'libraylib.a').is_file():
            say("building raylib's web library")
            if web_lib.exists():
                shutil.rmtree(web_lib)
            shutil.copytree(source / 'src', web_lib)
            # The native build's objects come with the sources, and make would take them as made: gone, so every one is compiled for wasm.
            for made in list(web_lib.glob('*.o')) + list(web_lib.glob('*.a')):
                made.unlink()
            run(['make', '-C', web_lib, 'PLATFORM=PLATFORM_WEB', 'CUSTOM_CFLAGS=-O3', f'RAYLIB_RELEASE_PATH={web_lib}', f'-j{os.cpu_count() or 4}'], env=emsdk)
    for program in programs:
        home = OUT / 'raylib-c' / program
        if program == 'bunnymark':
            variants = [('', [])]
            file, asset = 'bunnymark.c', source / 'examples/textures/resources/wabbit_alpha.png'
            asset_dir, asset_name = 'resources', 'wabbit_alpha.png'
        else:
            variants = [('cpu', []), ('gpu', ['-DGPU'])]
            file, asset = 'skin.c', source / 'examples/models/resources/models/gltf/robot.glb'
            asset_dir, asset_name = '', 'robot.glb'
        for variant, defines in variants:
            if native:
                directory = home / ('native-' + variant if variant else 'native')
                (directory / asset_dir).mkdir(parents=True, exist_ok=True)
                shutil.copy(asset, directory / asset_dir / asset_name)
                say(f'building raylib-c {program} {variant} natively')
                run(['cc', '-O2', '-std=c99', '-D_GNU_SOURCE', '-DPLATFORM_DESKTOP', *defines, '-I', source / 'src', here / file,
                     source / 'src/libraylib.a', *raylib_parity.LINK, '-lm', '-o', directory / 'program'])
            if page and emsdk is not None:
                directory = home / ('web-' + variant if variant else 'web')
                work = directory / 'preload'
                (work / asset_dir).mkdir(parents=True, exist_ok=True)
                shutil.copy(asset, work / asset_dir / asset_name)
                say(f'building raylib-c {program} {variant} page')
                run(['emcc', '-O3', '-std=gnu99', '-DPLATFORM_WEB', *defines, '-I', web_lib, here / file, web_lib / 'libraylib.a', '-sUSE_GLFW=3',
                     '-sALLOW_MEMORY_GROWTH=1', '--preload-file', (asset_dir or asset_name), '--shell-file', here / 'shell.html', '-o', directory / 'index.html'],
                    cwd=work, env=emsdk)


def build_godot(programs, page, native):
    """Godot's projects imported and exported, natively and for the web, with its binary."""
    binary = godot_binary()
    if binary is None:
        say('godot skipped: no binary (HELIX_GODOT, godot on PATH, or ~/toolchains/godot)')
        return False
    source = raylib_source()
    projects = {'bunnymark': ['bunnymark-nodes', 'bunnymark-multimesh'], 'robots': ['robots']}
    for program in programs:
        for project in projects[program]:
            home = OUT / 'godot' / project
            work = home / 'project'
            if work.exists():
                shutil.rmtree(work)
            shutil.copytree(CONTENDERS_DIR / 'godot' / project, work)
            asset = source / ('examples/textures/resources/wabbit_alpha.png' if program == 'bunnymark' else 'examples/models/resources/models/gltf/robot.glb')
            shutil.copy(asset, work / asset.name)
            say(f'exporting godot {project}')
            run([binary, '--headless', '--import'], cwd=work, timeout=600)
            if native:
                (home / 'linux').mkdir(parents=True, exist_ok=True)
                run([binary, '--headless', '--export-release', GODOT_PRESETS['linux'], home / 'linux' / 'program.x86_64'], cwd=work, timeout=900)
            if page:
                (home / 'web').mkdir(parents=True, exist_ok=True)
                run([binary, '--headless', '--export-release', GODOT_PRESETS['web'], home / 'web' / 'index.html'], cwd=work, timeout=900)
    return True


def build_three(programs, native):
    """three.js's pages: its module and addons installed with npm at the pinned version beside them, and each page bundled with esbuild for
    the size it would ship at. With native, Electron too, which runs each page as a desktop program."""
    if shutil.which('npm') is None:
        say('three skipped: no npm')
        return False
    versions = pins()
    npm = OUT / 'three/npm'
    npm.mkdir(parents=True, exist_ok=True)
    wanted = {'three': versions['three'], 'esbuild': versions['esbuild']}
    if native:
        wanted['electron'] = versions['electron']
    installed = {}
    lock = npm / 'package-lock.json'
    if lock.is_file():
        packages = json.loads(lock.read_text(encoding='utf-8')).get('packages', {})
        installed = {name: packages.get(f'node_modules/{name}', {}).get('version') for name in wanted}
    if installed != wanted:
        say('installing ' + ', '.join(f'{name} {version}' for name, version in wanted.items()))
        (npm / 'package.json').write_text(json.dumps({'name': 'speed-three', 'private': True, 'dependencies': {k: v for k, v in wanted.items()}}) + '\n',
                                          encoding='utf-8')
        run(['npm', 'install', '--no-audit', '--no-fund', '--silent'], cwd=npm, timeout=900)
    # Electron's binary is fetched by its package's install script, which npm may not run.
    if native and not ELECTRON.is_file():
        say(f'fetching Electron {wanted["electron"]}')
        run(['node', npm / 'node_modules/electron/install.js'], cwd=npm, timeout=900)
    modules = npm / 'node_modules/three'
    source = raylib_source()
    for program in programs:
        name = 'bunny' if program == 'bunnymark' else 'robots'
        home = OUT / 'three' / name
        home.mkdir(parents=True, exist_ok=True)
        for file in (CONTENDERS_DIR / 'three' / name).iterdir():
            shutil.copy(file, home / file.name)
        for file in ('three.module.js', 'three.core.js'):
            shutil.copy(modules / 'build' / file, home / file)
        if program == 'robots':
            for addon in ('loaders/GLTFLoader.js', 'utils/SkeletonUtils.js', 'utils/BufferGeometryUtils.js'):
                (home / 'addons' / addon).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(modules / 'examples/jsm' / addon, home / 'addons' / addon)
            shutil.copy(source / 'examples/models/resources/models/gltf/robot.glb', home / 'robot.glb')
        else:
            shutil.copy(source / 'examples/textures/resources/wabbit_alpha.png', home / 'wabbit_alpha.png')
        say(f'bundling three {name} with esbuild')
        run([npm / 'node_modules/.bin/esbuild', home / f'{name}.js', '--bundle', '--minify', '--format=esm',
             f'--alias:three/addons={modules}/examples/jsm', f'--alias:three={modules}/build/three.module.js', f'--outfile={home}/bundled/{name}.min.js'])
    return True


def build_lime(programs):
    """Lime's own BunnyMark demo shaped as the bunnymark (tools/speed/contenders/lime/bunnymark), built with `haxelib run lime build html5
    -release` from the user's haxelib, where lime is installed at the version dependencies.json pins; skipped without it."""
    if 'bunnymark' not in programs:
        return False
    env = dict(os.environ)
    env.pop('HAXELIB_PATH', None)
    listed = subprocess.run(['haxelib', 'list', 'lime'], capture_output=True, text=True, encoding='utf-8', env=env).stdout
    wanted = pins()['lime']
    if f'[{wanted}]' not in listed and f' {wanted}' not in listed:
        say(f'lime skipped: lime {wanted} is not installed in the user\'s haxelib (haxelib list lime: {listed.strip() or "none"})')
        return False
    home = OUT / 'lime/bunnymark'
    work = home / 'work'
    if work.exists():
        shutil.rmtree(work)
    shutil.copytree(CONTENDERS_DIR / 'lime/bunnymark', work)
    (work / 'Assets').mkdir(exist_ok=True)
    shutil.copy(raylib_source() / 'examples/textures/resources/wabbit_alpha.png', work / 'Assets')
    say('building lime bunnymark page')
    run(['haxelib', 'run', 'lime', 'build', 'html5', '-release'], cwd=work, env=env, timeout=900)
    web = home / 'web'
    if web.exists():
        shutil.rmtree(web)
    shutil.copytree(work / 'Export/html5/bin', web)
    return True


def build_legacy():
    """helix-legacy's bunnymark page, built as one of its examples by its tools/example.py (the program copied in as examples/bunnymark while it
    builds, and taken out again), its site and assets into build/speed/helix-legacy."""
    checkout = legacy_checkout()
    if checkout is None:
        say('helix-legacy skipped: no helix-legacy checkout (HELIX_LEGACY, or ../helix-legacy)')
        return False
    example = checkout / 'examples/bunnymark'
    placed = not example.exists()
    if placed:
        shutil.copytree(CONTENDERS_DIR / 'helix-legacy', example)
        (example / 'assets/bunnymark').mkdir(parents=True, exist_ok=True)
        shutil.copy(raylib_source() / 'examples/textures/resources/wabbit_alpha.png', example / 'assets/bunnymark/wabbit_alpha.png')
    try:
        say('building helix-legacy bunnymark page')
        run([sys.executable, 'tools/example.py', 'bunnymark', 'build', 'release-webgl2'], cwd=checkout, timeout=1800)
        site = checkout / 'out/js/release-webgl2/site'
        home = OUT / 'helix-legacy'
        if home.exists():
            shutil.rmtree(home)
        shutil.copytree(site / 'bunnymark', home)
        shutil.copytree(site / 'assets', home / 'assets')
    finally:
        if placed:
            shutil.rmtree(example, ignore_errors=True)
    return True


def build(programs, contenders, page, native):
    """Builds what the run needs under build/.lock; the contenders that built."""
    LOCK.parent.mkdir(parents=True, exist_ok=True)
    built = []
    with LOCK.open('w') as lock:
        say('waiting for build/.lock')
        if fcntl is not None:
            fcntl.flock(lock, fcntl.LOCK_EX)
        for contender in contenders:
            if contender == 'helix-raylib':
                build_helix_raylib(programs, page, native)
            elif contender == 'raylib-c':
                build_raylib_c(programs, page, native)
            elif contender == 'godot':
                if not build_godot(programs, page, native):
                    continue
            elif contender == 'three':
                if not build_three(programs, native):
                    continue
            elif contender == 'lime':
                if not page or not build_lime(programs):
                    continue
            elif contender == 'helix-legacy':
                if not page or 'bunnymark' not in programs or not build_legacy():
                    continue
            built.append(contender)
    return built


# ---- The programs to run ----


def pages(programs, contenders):
    """Each page to run: (contender, variant, program, directory, query maker, viewport). A variant is the contender's way of drawing."""
    found = []
    for program in programs:
        size = (800, 450) if program == 'bunnymark' else (1280, 720)
        plain = lambda mode: mode  # noqa: E731
        if 'helix-raylib' in contenders:
            found.append(('helix-raylib', '', program, OUT / 'helix-raylib' / program / 'web', plain, size))
        if 'raylib-c' in contenders:
            if program == 'bunnymark':
                found.append(('raylib-c', '', program, OUT / 'raylib-c/bunnymark/web', plain, size))
            else:
                for variant in ('gpu', 'cpu'):
                    found.append(('raylib-c', variant.upper() + ' skinning', program, OUT / 'raylib-c/robots' / f'web-{variant}', plain, size))
        if 'godot' in contenders:
            if program == 'bunnymark':
                found.append(('godot', 'MultiMesh', program, OUT / 'godot/bunnymark-multimesh/web', plain, size))
                found.append(('godot', 'a Sprite2D each', program, OUT / 'godot/bunnymark-nodes/web', plain, size))
            else:
                found.append(('godot', '', program, OUT / 'godot/robots/web', plain, size))
        if 'three' in contenders:
            if program == 'bunnymark':
                found.append(('three', 'InstancedMesh', program, OUT / 'three/bunny', plain, size))
                found.append(('three', 'a Sprite each', program, OUT / 'three/bunny', lambda mode: mode + '&variant=sprite', size))
            else:
                found.append(('three', '', program, OUT / 'three/robots', plain, size))
        if 'lime' in contenders and program == 'bunnymark':
            found.append(('lime', '', program, OUT / 'lime/bunnymark/web', plain, size))
        if 'helix-legacy' in contenders and program == 'bunnymark':
            found.append(('helix-legacy', 'a Sprite2D each', program, OUT / 'helix-legacy', plain, size))
    return [p for p in found if (p[3] / 'index.html').is_file()]


def natives(programs, contenders):
    """Each native program to run: (contender, variant, program, where, command maker, directory)."""
    found = []
    godot_args = ['--audio-driver', 'Dummy']
    for program in programs:
        if 'helix-raylib' in contenders:
            for backend in ('native-gl', 'native-sdlgpu'):
                home = OUT / 'helix-raylib' / program / backend
                found.append(('helix-raylib', '', program, backend, lambda mode, h=home: [str(h / 'Main'), '--' + mode], home))
        if 'raylib-c' in contenders:
            if program == 'bunnymark':
                home = OUT / 'raylib-c/bunnymark/native'
                found.append(('raylib-c', '', program, 'native-gl', lambda mode, h=home: [str(h / 'program'), '--' + mode], home))
            else:
                for variant in ('gpu', 'cpu'):
                    home = OUT / 'raylib-c/robots' / f'native-{variant}'
                    found.append(('raylib-c', variant.upper() + ' skinning', program, 'native-gl', lambda mode, h=home: [str(h / 'program'), '--' + mode], home))
        if 'three' in contenders and ELECTRON.is_file():
            size = (800, 450) if program == 'bunnymark' else (1280, 720)
            home = OUT / 'three' / ('bunny' if program == 'bunnymark' else 'robots')
            variants = [('InstancedMesh', ''), ('a Sprite each', '&variant=sprite')] if program == 'bunnymark' else [('', '')]
            for variant, extra in variants:
                found.append(('three', variant, program, 'native-electron',
                              lambda mode, angle='gl', h=home, e=extra, z=size: ['node', str(HERE / 'run_page.cjs'), '--electron', str(ELECTRON), str(h),
                                                                                  mode + e, str(PAGE_SECONDS['ramp' if mode.startswith('ramp') else 'count']),
                                                                                  angle, str(z[0]), str(z[1])], home))
        if 'godot' in contenders:
            projects = [('bunnymark-multimesh', 'MultiMesh'), ('bunnymark-nodes', 'a Sprite2D each')] if program == 'bunnymark' else [('robots', '')]
            for project, variant in projects:
                home = OUT / 'godot' / project / 'linux'
                for where, method in (('native-vulkan', 'forward_plus'), ('native-gl', 'gl_compatibility')):
                    if program == 'robots' and where == 'native-vulkan':
                        continue
                    found.append(('godot', variant, program, where,
                                  lambda mode, h=home, m=method: [str(h / 'program.x86_64'), *godot_args, '--rendering-method', m, '--', '--' + mode], home))
    return [n for n in found if n[5].is_dir() and any(n[5].iterdir())]


# ---- Running ----


def found_line(output):
    """The program's JSON line in its output, or None."""
    lines = [line for line in output.splitlines() if line.startswith('{') and '"contender"' in line]
    try:
        return json.loads(lines[-1]) if lines else None
    except ValueError:
        return None


def run_page(browser, directory, query, backend, size, mode, headed):
    """One page run, in the browser's window on the display when headed; its result (None when none came) and what the runner reported."""
    seconds = PAGE_SECONDS['ramp' if mode.startswith('ramp') else 'count']
    env = dict(os.environ)
    env.pop('DBUS_SESSION_BUS_ADDRESS', None)
    try:
        done = subprocess.run(['node', str(HERE / 'run_page.cjs'), '--headed' if headed else '--headless', browser, str(directory), query, str(seconds), backend, str(size[0]), str(size[1])],
                              capture_output=True, text=True, encoding='utf-8', env=env, timeout=seconds + 120)
    except subprocess.TimeoutExpired:
        return None, {'errors': ['the page runner timed out']}
    try:
        printed = json.loads(done.stdout.strip().splitlines()[-1])
    except (IndexError, ValueError):
        return None, {'errors': [(done.stdout + done.stderr)[-600:]]}
    return printed['result'], printed


def run_native(command, directory, display, mode, where):
    """One native run in the program's directory; its result and the output's tail. Electron's is run_page.cjs's, its line the page's."""
    seconds = (PAGE_SECONDS if where == 'native-electron' else NATIVE_SECONDS)['ramp' if mode.startswith('ramp') else 'count'] + 120
    env = dict(display, SDL_AUDIO_DRIVER='dummy')
    env.pop('DBUS_SESSION_BUS_ADDRESS', None)
    try:
        done = subprocess.run(command, cwd=directory, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=seconds)
    except subprocess.TimeoutExpired:
        return None, f'no result in {seconds} s'
    line = found_line(done.stdout)
    if line is not None and 'files' in line:
        line = line['result']
    return line, (done.stdout + done.stderr)[-600:]


def modes_of(program):
    counts = BUNNY_COUNTS if program == 'bunnymark' else ROBOT_COUNTS
    return [f'count={n}' for n in counts] + (['ramp=1'] if program == 'bunnymark' else [])


def measure(programs, contenders, page, native, backends, runs, headed, browser, record):
    """Every run, round-robin so a drift in the machine's state spreads over every program, each recorded. Pages over Vulkan run headless
    even when headed: a visible window loses its WebGL context at startup there."""
    for backend in backends if page else []:
        for run_index in range(1, runs + 1):
            for contender, variant, program, directory, query, size in pages(programs, contenders):
                for mode in modes_of(program):
                    result, printed = run_page(browser, directory, query(mode), backend, size, mode, headed and backend == 'gl')
                    record({'where': f'page-{backend}', 'contender': contender, 'variant': variant, 'program': program, 'mode': mode, 'run': run_index,
                            'result': result, 'files': printed.get('files'), 'renderer': printed.get('renderer'), 'errors': printed.get('errors')})
    if native:
        def every(display):
            for run_index in range(1, runs + 1):
                for contender, variant, program, where, command, directory in natives(programs, contenders):
                    for mode in modes_of(program):
                        # Electron draws over GL on the display, and off it in software (SwiftShader), as the others do there.
                        given = command(mode, 'gl' if headed else 'swiftshader') if where == 'native-electron' else command(mode)
                        result, tail = run_native(given, directory, display, mode, where)
                        record({'where': where, 'contender': contender, 'variant': variant, 'program': program, 'mode': mode, 'run': run_index,
                                'result': result, 'tail': None if result else tail})
        if headed:
            say('native runs in windows on $DISPLAY=' + os.environ['DISPLAY'])
            every(dict(os.environ))
        else:
            from private_display import private_display
            say('native runs on a private display (software GL): these times are not representative; --headed runs them on the real one')
            with private_display() as display:
                every(display)


# ---- Sizes and the store ----


def compressed(files):
    """The bytes of files together, raw, gzip -9 and brotli -q 11 (None without the tool), in KB."""
    raw = gz = br = 0
    brotli = shutil.which('brotli')
    for file in files:
        data = Path(file).read_bytes()
        raw += len(data)
        gz += len(gzip.compress(data, 9, mtime=0))
        if brotli:
            br += len(subprocess.run([brotli, '-c', '-q', '11'], input=data, capture_output=True).stdout)
    return {'rawKB': round(raw / 1000, 1), 'gzipKB': round(gz / 1000, 1), 'brotliKB': round(br / 1000, 1) if brotli else None}


def page_size(directory, fetched):
    """A page's code as fetched: every file but the assets."""
    files = [directory / f['path'].lstrip('/') for f in fetched or [] if f.get('status') == 200 and not f['path'].lower().endswith(ASSET_SUFFIXES)]
    files = [f for f in dict.fromkeys(files) if f.is_file()]
    return compressed(files) if files else None


def native_size(program):
    """A native program's size stripped, in MB, or None."""
    if not Path(program).is_file():
        return None
    copy = OUT / 'stripped.tmp'
    done = subprocess.run(['strip', '-o', str(copy), str(program)], capture_output=True)
    size = (copy if done.returncode == 0 and copy.is_file() else Path(program)).stat().st_size
    copy.unlink(missing_ok=True)
    return round(size / 1e6, 2)


def electron_size(program):
    """three.js's program as a desktop one: Electron's files, as installed, and the page bundled, in MB."""
    files = [f for f in ELECTRON.parent.rglob('*') if f.is_file()]
    bundled = OUT / 'three' / ('bunny' if program == 'bunnymark' else 'robots') / 'bundled'
    files += [f for f in bundled.rglob('*') if f.is_file()]
    return round(sum(f.stat().st_size for f in files) / 1e6, 1)


def versions_of(contenders):
    """What each contender is, for its rows: its version."""
    versions = pins()
    commit = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    return {'helix-raylib': f'helix {commit}', 'raylib-c': f'raylib {RAYLIB}', 'godot': f'Godot {versions["godot"]}', 'three': f'three.js {versions["three"]}',
            'lime': f'Lime {versions["lime"]}', 'helix-legacy': 'helix-legacy'}


def electron_version(row):
    """The Electron a three.js row ran in: the store's, or the pinned one."""
    return row.get('electron') or pins()['electron']


def machine():
    """This machine, for the rows: its name, processor and GPU."""
    cpu = ''
    for line in Path('/proc/cpuinfo').read_text(encoding='utf-8', errors='replace').splitlines():
        if line.startswith('model name'):
            cpu = line.split(':', 1)[1].strip()
            break
    gpu = subprocess.run(['sh', '-c', "lspci 2>/dev/null | grep -i 'vga\\|3d' | head -1 | sed 's/.*: //'"], capture_output=True, text=True).stdout.strip()
    return f'{os.uname().nodename}: {cpu}, {gpu}, {os.uname().sysname}'.strip(', ')


def median(rows, key):
    values = [row['result'][key] for row in rows if row['result'] and key in row['result']]
    return round(statistics.median(values), 2) if values else None


def summarize(rows, date, built):
    """The run's rows for the store: each contender x variant x program x where with its counts' medians, its most held, its size."""
    versions = versions_of(built)
    host = machine()
    groups = {}
    for row in rows:
        groups.setdefault((row['contender'], row['variant'], row['program'], row['where']), []).append(row)
    out = []
    for (contender, variant, program, where), runs in groups.items():
        counts = {}
        for mode in dict.fromkeys(r['mode'] for r in runs):
            same = [r for r in runs if r['mode'] == mode]
            if mode.startswith('count='):
                counts[mode[6:]] = {'meanMs': median(same, 'mean_ms'), 'p95Ms': median(same, 'p95_ms'), 'runs': sum(1 for r in same if r['result'])}
        ramps = [r for r in runs if r['mode'] == 'ramp=1']
        held = median(ramps, 'ramp_max')
        entry = {'contender': contender, 'variant': variant, 'program': program, 'where': where, 'version': versions[contender], 'date': date, 'machine': host,
                 'counts': counts, 'held': int(held) if held is not None else None}
        if where == 'native-electron':
            entry['electron'] = pins()['electron']
        if where.startswith('page'):
            first = next((r for r in runs if r.get('files')), None)
            directory = next(p[3] for p in pages([program], [contender]) if p[0] == contender and p[1] == variant) if first else None
            entry['size'] = page_size(directory, first['files']) if first else None
            if contender == 'three' and directory is not None:
                bundled = directory / 'bundled' / (('bunny' if program == 'bunnymark' else 'robots') + '.min.js')
                entry['bundledSize'] = compressed([bundled]) if bundled.is_file() else None
            renderer = next((r['renderer'] for r in runs if r.get('renderer')), None)
            entry['renderer'] = renderer.get('webgl2') if isinstance(renderer, dict) else renderer
        elif where == 'native-electron':
            entry['size'] = {'appMB': electron_size(program)}
        else:
            spec = next((n for n in natives([program], [contender]) if n[0] == contender and n[1] == variant and n[3] == where), None)
            entry['size'] = {'strippedMB': native_size(spec[4]('count=1')[0])} if spec else None
        out.append(entry)
    return out


def load_store():
    return json.loads(STORE.read_text(encoding='utf-8')) if STORE.is_file() else {'rows': []}


def write_store(entries):
    """docs/speed.json with these rows in place of the ones they name, the others kept."""
    store = load_store()
    keys = {(e['contender'], e['variant'], e['program'], e['where']) for e in entries}
    kept = [r for r in store['rows'] if (r['contender'], r['variant'], r['program'], r['where']) not in keys]
    store['rows'] = sorted(kept + entries, key=lambda r: (r['program'], r['where'].startswith('native'), r['where'], CONTENDERS.index(r['contender']), r['variant']))
    STORE.write_text(json.dumps(store, indent=1) + '\n', encoding='utf-8')
    return store


# ---- docs/benchmarks.md ----

WHERE = {'page-vulkan': 'page', 'page-gl': 'page', 'native-gl': 'native, GL', 'native-sdlgpu': 'native, SDL_GPU (Vulkan)', 'native-vulkan': 'native, Vulkan',
         'native-electron': 'native, Electron'}
API = {('helix-raylib', 'page'): 'WebGL2', ('raylib-c', 'page'): 'wasm, WebGL1', ('godot', 'page'): 'wasm, WebGL2', ('three', 'page'): 'WebGL2',
       ('helix-legacy', 'page'): 'WebGL2', ('lime', 'page'): 'WebGL', ('godot', 'native-vulkan'): 'Forward+', ('godot', 'native-gl'): 'Compatibility'}


def label(row):
    name = {'helix-raylib': '**helix-raylib**', 'raylib-c': 'raylib C ' + row['version'].split()[-1], 'godot': 'Godot ' + row['version'].split()[-1],
            'three': 'three.js ' + row['version'].split()[-1], 'lime': 'Lime ' + row['version'].split()[-1], 'helix-legacy': 'helix-legacy'}[row['contender']]
    return name + (f', {row["variant"]}' if row['variant'] else '')


def where_text(row, newest):
    kind = 'page' if row['where'].startswith('page') else row['where']
    api = API.get((row['contender'], kind)) or API.get((row['contender'], 'page' if kind == 'page' else kind))
    text = WHERE[row['where']] + (f' {electron_version(row)}' if row['where'] == 'native-electron' else '') + (f', {api}' if api else '')
    if row['date'] != newest:
        text += f' ({row["date"]})'
    return text


def size_text(row):
    size = row.get('size')
    if not size:
        return ''
    if 'strippedMB' in size:
        return f'{size["strippedMB"]:.1f} MB'
    if 'appMB' in size:
        return f'{size["appMB"]:,.1f} MB'
    bundled = row.get('bundledSize')
    if bundled:
        return f'{bundled["gzipKB"]:,.1f} KB bundled ({size["gzipKB"]:,.1f} as served)'
    return f'{size["gzipKB"]:,.1f} KB'


def cell(count):
    return f'{count["meanMs"]:.2f}' if count and count.get('meanMs') is not None else ''


def table(rows, program, wheres):
    """A markdown table of the rows of a program at these wheres, pages first, each contender in order."""
    rows = [r for r in rows if r['program'] == program and r['where'] in wheres]
    if not rows:
        return ['(no rows yet)']
    newest = max(r['date'] for r in rows)
    counts = [str(n) for n in (BUNNY_COUNTS if program == 'bunnymark' else ROBOT_COUNTS)]
    heads = [f'{int(n) // 1000}k' if int(n) >= 1000 else n for n in counts]
    held = program == 'bunnymark'
    lines = ['| program | where | ' + ' | '.join(heads) + (' | most held' if held else '') + ' | size |',
             '|---|---|' + '---:|' * len(counts) + ('---:|' if held else '') + '---:|']
    order = {w: i for i, w in enumerate(wheres)}
    for row in sorted(rows, key=lambda r: (order[r['where']], CONTENDERS.index(r['contender']), r['variant'])):
        cells = [cell(row['counts'].get(n)) for n in counts]
        most = f'{row["held"] // 1000}k' if held and row.get('held') else ('' if held else None)
        lines.append('| ' + ' | '.join([label(row), where_text(row, newest)] + cells + ([most] if held else []) + [size_text(row)]) + ' |')
    return lines


def write_page_tables(store):
    """docs/benchmarks.md's speed tables, between their markers, from the store."""
    text = PAGE.read_text(encoding='utf-8')
    sections = {'bunnymark': table(store['rows'], 'bunnymark', ['page-vulkan', 'native-gl', 'native-sdlgpu', 'native-vulkan', 'native-electron']),
                'robots': table(store['rows'], 'robots', ['page-vulkan', 'native-gl', 'native-sdlgpu', 'native-electron']),
                'bunnymark-gl': table(store['rows'], 'bunnymark', ['page-gl']),
                'robots-gl': table(store['rows'], 'robots', ['page-gl'])}
    for name, lines in sections.items():
        start, end = f'<!-- gen_speed: {name} -->', f'<!-- /gen_speed: {name} -->'
        if start not in text or end not in text:
            raise SystemExit(f'gen_speed: docs/benchmarks.md has no {start} ... {end} markers')
        head, rest = text.split(start, 1)
        _, tail = rest.split(end, 1)
        text = head + start + '\n' + '\n'.join(lines) + '\n' + end + tail
    PAGE.write_text(text, encoding='utf-8')


# ---- docs/benchmarks/*.svg ----

CHARTS = ROOT / 'docs/benchmarks'
# The rows a chart shows, pages first: a page over Vulkan, then each native backend.
CHART_WHERES = ['page-vulkan', 'native-gl', 'native-sdlgpu', 'native-vulkan', 'native-electron']
# Light and dark: the surface, the text, the grid, and helix-raylib's, the control's and the others' marks.
CHART_STYLE = """
svg { font: 12px system-ui, -apple-system, 'Segoe UI', sans-serif; }
.surface { fill: #fcfcfb; } .text { fill: #0b0b0b; } .muted { fill: #52514e; } .grid { stroke: #e4e3df; } .axis { stroke: #b5b4ae; }
.helix-raylib { fill: #2a78d6; } .raylib-c { fill: #eb6834; } .other { fill: #8a8984; }
@media (prefers-color-scheme: dark) {
  .surface { fill: #1a1a19; } .text { fill: #f0efec; } .muted { fill: #c3c2b7; } .grid { stroke: #33332f; } .axis { stroke: #5c5b55; }
  .helix-raylib { fill: #3987e5; } .raylib-c { fill: #d95926; } .other { fill: #8f8e88; }
}"""


def escape(text):
    return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def ceiling(value):
    """The round number at or above value an axis ends at: 1, 2 or 5 times a power of ten."""
    import math
    power = 10 ** math.floor(math.log10(value))
    return next(step * power for step in (1, 2, 5, 10) if step * power >= value)


def chart_size(row):
    """A row's size for the charts: a page's gzipped code (three's bundled), a native program's MB."""
    size = row.get('size') or {}
    if row['where'].startswith('page'):
        return (row.get('bundledSize') or size).get('gzipKB')
    return size.get('strippedMB') or size.get('appMB')


def bars(program, rows, measure):
    """One horizontal bar chart of a program's rows, pages and native programs apart, each group sorted from the best: frame time at
    the largest count (measure 'speed') or size ('size'). An axis ends near ten times its group's best; a longer bar breaks at the
    edge and says its value."""
    count = str((BUNNY_COUNTS if program == 'bunnymark' else ROBOT_COUNTS)[-1])
    shown = f'{int(count) // 1000}k bunnies' if program == 'bunnymark' else f'{count} robots'
    order = {w: i for i, w in enumerate(CHART_WHERES)}
    rows = [r for r in rows if r['program'] == program and r['where'] in order]
    newest = max(r['date'] for r in rows)
    value_of = (lambda r: r['counts'].get(count, {}).get('meanMs')) if measure == 'speed' else chart_size
    name = 'The bunnymark' if program == 'bunnymark' else 'Animated robots'
    title = f'{name}: frame time at {shown}, ms (shorter is faster)' if measure == 'speed' else f'{name}: size (shorter is smaller)'
    width, label_width, plot, row_height, bar = 1040, 400, 520, 24, 14
    groups = []
    for group, kind in (('Page', 'page'), ('Native', 'native')):
        members = sorted([r for r in rows if r['where'].startswith(kind)], key=lambda r: (value_of(r) is None, value_of(r) or 0))
        if members:
            unit = ('ms' if measure == 'speed' else 'KB gzip' if kind == 'page' else 'MB')
            values = [value_of(r) for r in members if value_of(r)]
            groups.append((group, unit, members, ceiling(min(values) * 10) if values else 1))
    height = 56 + sum(34 + len(m) * row_height for _, _, m, _ in groups) + 26
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img">',
           f'<title>{escape(title)}</title>', f'<style>{CHART_STYLE}</style>',
           f'<rect class="surface" width="{width}" height="{height}" rx="8"/>',
           f'<text class="text" x="16" y="28" font-size="15" font-weight="600">{escape(title)}</text>']
    y = 56
    for group, unit, members, end in groups:
        left = label_width
        out.append(f'<text class="text" x="16" y="{y + 14}" font-weight="600">{group}</text>')
        bottom = y + 22 + len(members) * row_height
        for i in range(5):
            tick = end * i / 4
            x = left + plot * i / 4
            out.append(f'<line class="{"axis" if i == 0 else "grid"}" x1="{x:.1f}" y1="{y + 20}" x2="{x:.1f}" y2="{bottom}" stroke-width="1"/>')
            out.append(f'<text class="muted" x="{x:.1f}" y="{y + 14}" text-anchor="middle" font-size="11">{tick:,g}{" " + unit if i == 4 else ""}</text>')
        y += 22
        for row in members:
            mark = row['contender'] if row['contender'] in ('helix-raylib', 'raylib-c') else 'other'
            where = where_text(row, newest).removeprefix('page').removeprefix('native').lstrip(', ')
            label_text = label(row).replace('**', '') + (' — ' + where if where else '')
            middle = y + row_height / 2
            out.append(f'<g><title>{escape(label_text)}</title>')
            out.append(f'<text class="{"text" if mark != "other" else "muted"}" x="16" y="{middle + 4:.1f}"{" font-weight=\"600\"" if mark == "helix-raylib" else ""}>'
                       f'{escape(label_text if len(label_text) <= 62 else label_text[:61] + "…")}</text>')
            value = value_of(row)
            if value:
                broken = value > end
                length = plot if broken else max(plot * value / end, 2)
                top = middle - bar / 2
                # The bar starts square at the axis and ends rounded at its value.
                out.append(f'<path class="{mark}" d="M{left},{top:.1f} h{length - 4:.1f} a4,4 0 0 1 4,4 v{bar - 8} a4,4 0 0 1 -4,4 h{-(length - 4):.1f} z"/>')
                if broken:
                    for offset in (14, 20):
                        x = left + plot - offset
                        out.append(f'<line class="grid" x1="{x - 3:.1f}" y1="{top + bar + 2:.1f}" x2="{x + 3:.1f}" y2="{top - 2:.1f}" stroke-width="3"/>')
                text = f'{value:,.2f}' if measure == 'speed' else f'{value:,.1f}'
                out.append(f'<text class="text" x="{left + length + 6:.1f}" y="{middle + 4:.1f}" font-size="11">{text}{" →" if broken else ""}</text>')
            else:
                out.append(f'<text class="muted" x="{left + 6}" y="{middle + 4:.1f}" font-size="11">not measured at {shown}</text>')
            out.append('</g>')
            y += row_height
        y += 12
    out.append(f'<text class="muted" x="16" y="{height - 12}" font-size="11">Blue: helix-raylib. Orange: raylib C, the control. A broken bar '
               'runs past the axis, its value beside it. Each row as measured on its date; the tables below have every count.</text>')
    out.append('</svg>')
    return '\n'.join(out) + '\n'


def write_charts(store):
    """docs/benchmarks/<program>-speed.svg and <program>-size.svg for each program, from the store."""
    CHARTS.mkdir(parents=True, exist_ok=True)
    for program in PROGRAMS:
        for measure in ('speed', 'size'):
            (CHARTS / f'{program}-{measure}.svg').write_text(bars(program, store['rows'], measure), encoding='utf-8')


# ---- Main ----


def stale(programs, wheres, store, control):
    """The contenders a run takes when none is named: helix-raylib, raylib C as the control unless not control, and each other one with a
    row missing here or measured at another version than its pin."""
    versions = versions_of(CONTENDERS)
    found = ['helix-raylib'] + (['raylib-c'] if control else [])
    for contender in CONTENDERS[2:]:
        rows = [r for r in store['rows'] if r['contender'] == contender and r['program'] in programs]
        for where in set(wheres) & set(WHERES[contender]):
            here = [r for r in rows if r['where'] == where]
            if not here or any(r['version'] != versions[contender] or (where == 'native-electron' and r.get('electron') != pins()['electron'])
                               for r in here):
                found.append(contender)
                break
    return found


def unquiet():
    """Why this machine can't be timed now, or None: a load average over QUIET_LOAD, or a pinned loop slower than QUIET_LOOP_SECONDS."""
    load = os.getloadavg()[0]
    if load > QUIET_LOAD:
        return f'the load average is {load:.2f}, over {QUIET_LOAD}: something else is running'
    loop = 'x=0\nfor i in range(20_000_000):x+=i'
    pinned = ['taskset', '-c', '2'] if shutil.which('taskset') else []
    started = time.perf_counter()
    subprocess.run([*pinned, sys.executable, '-c', loop], check=True)
    seconds = time.perf_counter() - started
    if seconds > QUIET_LOOP_SECONDS:
        return (f'a pinned loop took {seconds:.2f} s, over {QUIET_LOOP_SECONDS}: the CPU is held back '
                '(system76-power profile performance, or a power cycle when that is not enough)')
    return None


def drift(entries, store):
    """How far the control moved from its rows in the store: the median of its counts' ratios, new to old, or None without both."""
    old = {(r['variant'], r['program'], r['where']): r for r in store['rows'] if r['contender'] == 'raylib-c'}
    ratios = []
    for entry in entries:
        before = old.get((entry['variant'], entry['program'], entry['where'])) if entry['contender'] == 'raylib-c' else None
        for count, now in entry['counts'].items() if before else []:
            then = before['counts'].get(count, {}).get('meanMs')
            if then and now.get('meanMs'):
                ratios.append(now['meanMs'] / then)
    return statistics.median(ratios) if ratios else None


def main():
    parser = cli.parser(__doc__)
    cli.runs(parser)
    parser.add_argument('--backend', choices=['vulkan', 'gl'], default='vulkan', help="what ANGLE draws the pages over (default vulkan)")
    parser.add_argument('--all', action='store_true', help='every contender, and the pages over both backends')
    parser.add_argument('--runs', type=int, default=3, help='runs of each program and count (default 3)')
    parser.add_argument('--browser', default='', help="a Chromium to run the pages in (default Playwright's own)")
    parser.add_argument('--write', action='store_true', help="update docs/speed.json, docs/benchmarks.md's tables and its charts with the run")
    parser.add_argument('--no-control', action='store_true', help='leave raylib C, the control, out of a run naming no contender')
    parser.add_argument('--unchecked', action='store_true', help="write without the quiet machine's check and the control's")
    parser.add_argument('names', nargs='*', metavar='NAME', help='programs (bunnymark, robots) and contenders (helix-raylib, raylib-c, godot, three, lime, helix-legacy)')
    a = parser.parse_args()
    if not sys.platform.startswith('linux'):
        print('gen_speed: Linux only')
        return 1
    unknown = [n for n in a.names if n not in PROGRAMS + CONTENDERS]
    if unknown:
        print(f'gen_speed: unknown {", ".join(unknown)}: programs are {", ".join(PROGRAMS)}, contenders {", ".join(CONTENDERS)}')
        return 2
    programs = [n for n in PROGRAMS if n in a.names] or PROGRAMS
    native, page = cli.targets(a)
    backends = ['vulkan', 'gl'] if a.all else [a.backend]
    wheres = ([f'page-{b}' for b in backends] if page else []) + (['native-gl', 'native-sdlgpu', 'native-vulkan', 'native-electron'] if native else [])
    named = [n for n in CONTENDERS if n in a.names]
    contenders = named or (CONTENDERS if a.all else stale(programs, wheres, load_store(), not a.no_control))
    say('contenders: ' + ', '.join(contenders))
    if a.headed and not os.environ.get('DISPLAY'):
        print('gen_speed: --headed needs $DISPLAY')
        return 1
    if a.write and native and not a.headed:
        print('gen_speed: native times on the private display are software GL\'s, not written: --headed runs them on this one')
        return 2
    if a.write and 'raylib-c' not in contenders and not a.unchecked:
        print('gen_speed: not written without the control, raylib C: name it, or --unchecked writes without it')
        return 2
    if a.write and not a.unchecked:
        why = unquiet()
        if why:
            print(f'gen_speed: not timed, as {why} (--unchecked times it anyway)')
            return 1
    built = build(programs, contenders, page, native)
    stamp = time.strftime('%Y-%m-%d-%H%M%S')
    runs_file = OUT / 'runs' / f'{stamp}.jsonl'
    runs_file.parent.mkdir(parents=True, exist_ok=True)
    rows = []

    def record(row):
        rows.append(row)
        with runs_file.open('a', encoding='utf-8') as f:
            f.write(json.dumps(row) + '\n')
        result = row['result']
        shown = f'{result["mean_ms"]:.2f} ms' if result and 'mean_ms' in result else f'held {result["ramp_max"]}' if result and 'ramp_max' in result else 'FAILED'
        print(f'  {row["where"]:14} {row["contender"]:13} {row["variant"]:16} {row["program"]:10} {row["mode"]:13} run {row["run"]}: {shown}', flush=True)

    import screen_power
    with screen_power.kept_on(a.headed):
        measure(programs, built, page, native, backends, a.runs, a.headed, a.browser, record)
    say(f'{len(rows)} runs in {runs_file.relative_to(ROOT)}')
    entries = summarize(rows, time.strftime('%Y-%m-%d'), built)
    for e in entries:
        counts = ', '.join(f'{n}: {c["meanMs"]}' for n, c in e['counts'].items() if c['meanMs'] is not None)
        print(f'  {e["program"]} {e["where"]:14} {label(e):40} {counts}' + (f', held {e["held"]}' if e.get('held') else '') + f'  size {size_text(e)}')
    if a.write:
        moved = drift(entries, load_store())
        if moved is not None and abs(moved - 1) > CONTROL_DRIFT and not a.unchecked:
            say(f'not written: the control, raylib C, moved to {moved:.2f} times its last times, past {CONTROL_DRIFT:.0%} (--unchecked writes it)')
            return 1
        store = write_store(entries)
        write_page_tables(store)
        write_charts(store)
        say(f'{STORE.relative_to(ROOT)}, {PAGE.relative_to(ROOT)} and its charts written')
    return 1 if any(not r['result'] for r in rows) else 0


if __name__ == '__main__':
    sys.exit(main())
