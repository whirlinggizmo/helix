#!/usr/bin/env python3
"""Runs one entrant of the native blind trial (../README.md): claude -p in its own directory, on a private display, with no sound.

    python3 run_entrant.py <entrant directory> --helix <checkout> [--engine helix|c|three] [--extras] [--page] [--trial <variant>]
        [--game <folder>]
        [--model sonnet] [--hours 3] [--command CMD]

The entrant directory is made, and must not be there yet unless --command is given, from the spec, assets/ and raylib 5.5's C examples
(docs/examples), with the engine's own files:
- helix (helix-raylib, in Haxe): native/brief.md as brief.md (its {DIR} the directory's path), native/build.hxml with the company and
  product every program defines (helix-trials, and the directory's name, so each entrant's saves are its own), and raylib 5.5's headers
  in docs/include.
- c (the control, raylib 5.5 in C): native-c/brief.md as brief.md, native-c/CMakeLists.txt, raylib 5.5's headers in include/ and its desktop
  library as lib/libraylib.a.
- three (three.js 0.187, in JavaScript or TypeScript, for the browser): three/brief.md as brief.md, three/index.html, three/run.cjs (it
  bundles the game with esbuild and runs it in headless Chromium, Playwright's own, on SwiftShader), an empty src/, and three/package.json
  and package-lock.json, three.js and esbuild installed from them (npm ci) into the entrant's own node_modules, to which it may add from
  npm. No raylib files.
raylib's files are copied from the release tools/test_raylib_parity.py fetches and builds. A directory inside a git repository is refused,
as the entrant would see its commit messages.

--helix names the checkout of helix the tools come from and, for helix-raylib, the entrant builds against: a worktree at the commit
being tried, its build/haxelib made. The entrant's environment carries hxcpp's and the platform's settings from it and its haxelib,
no sound (SDL_AUDIO_DRIVER=dummy for SDL; for raylib C's miniaudio, no PulseAudio server and an ALSA whose one device is null), no
session D-Bus (SDL_OpenURL would reach the desktop's browser), and data and cache directories of its own beside the entrant
(.home/<name>), so entrants running at once keep their saves apart.

The entrant runs in a bubblewrap sandbox, as the brief's "write only here" and "read nothing else" are only asked of it: an empty home
with the Claude Code binary, the toolchains, the shared shader tools and the checkout read-only, and only ~/.claude (its session),
the checkout's build/ (its haxelib and hxcpp's cache), its directory and its .home writable; ~/.claude.json copied in. Everything
else in the home is hidden (the other checkouts and entrants, keys), and so are /dev's devices (gamepads among them), the user's
/run sockets (PulseAudio, D-Bus) and /tmp, which is its own but for the X server's socket. The JSON result (usage, cost, turns, duration) goes to result.json, stderr to stderr.log, the start and
end to run.log.

--extras gives a helix-raylib entrant the extras: native/brief-extras.md as its brief, and the checkout's generated API pages of the
extras (engines/raylib/api/extras-*.md, their doc comments) in docs/extras/, with the extras' part of the API index as its README.md,
and each extra's example program in docs/extras/examples/.

--page gives a helix-raylib entrant the extras and a page to build and run its program in as it works: page/brief.md as its brief,
page/build.hxml (native/'s), page/index.html and
page/run.cjs, which type-checks the native build, builds the program for the page and runs it in headless Chromium, Playwright's own,
on SwiftShader. The native build is the entrant's last step.

--trial names another trial's variant to make the entrant from in place of Wardens (helix-raylib only), as
../2026-11-15-lighting-shadows/module: the variant's files (its brief.md and what else it gives, as docs/extras/), then its trial's own
beside it (task.md, build.hxml; not its README.md or results.md), the assets its assets.txt lists from Wardens' assets/, and raylib 5.5's headers and C examples.

--game names another game's folder to build in place of Wardens, as ../templates/lanternholm: its spec.md, its assets/ and reference/ when it has
them, and each engine's brief from its native/, native-c/ or three/ when it has one there; the build files are always Wardens' own.

--command runs a shell command in the entrant's environment in place of claude, to check the harness."""
import argparse
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
# Wardens, the game an entrant builds unless --game names another, with each engine's brief and build files.
WARDENS = HERE.parent / 'templates/wardens'
PLAYWRIGHT_BROWSERS = Path(os.environ.get('PLAYWRIGHT_BROWSERS_PATH', Path.home() / '.cache/ms-playwright'))
# Claude Code's own session variables, so the entrant starts as a session of its own, not a child of the one starting it.
CLAUDE_VARS = ('CLAUDECODE', 'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_CODE_CHILD_SESSION', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_PID',
               'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'CLAUDE_CODE_BRIDGE_SESSION_ID',
               'CLAUDE_CODE_SESSION_ATTENDED', 'CLAUDE_CODE_EXECPATH', 'CLAUDE_EFFORT')

def log(entrant, line):
    with open(entrant / 'run.log', 'a', encoding='utf-8') as f:
        f.write(datetime.now().astimezone().isoformat(timespec='seconds') + ' ' + line + '\n')

def brief_of(game, own, name):
    """An engine's brief: the game's own (game/<own>/<name>) when it has one, else Wardens'."""
    mine = game / own / name
    return (mine if mine.exists() else WARDENS / own / name).read_text(encoding='utf-8')

def game_files(entrant, game):
    """Copies a game's spec, and its assets and reference screenshots when it has them."""
    shutil.copy(game / 'spec.md', entrant / 'spec.md')
    for folder in ('assets', 'reference'):
        if (game / folder).is_dir():
            shutil.copytree(game / folder, entrant / folder)

def make(entrant, engine, trial=None, extras=None, game=WARDENS, page=False):
    """Makes the entrant's directory from the game's files and raylib 5.5's, or from another trial's variant."""
    if engine == 'three':
        entrant.mkdir(parents=True)
        brief = brief_of(game, 'three', 'brief.md')
        (entrant / 'brief.md').write_text(brief.replace('{DIR}', str(entrant)), encoding='utf-8')
        for name in ('index.html', 'run.cjs', 'package.json', 'package-lock.json'):
            shutil.copy(WARDENS / 'three' / name, entrant / name)
        (entrant / 'src').mkdir()
        subprocess.run(['npm', 'ci', '--no-audit', '--no-fund'], cwd=entrant, check=True)
        game_files(entrant, game)
        return
    import test_raylib_parity
    raylib = test_raylib_parity.raylib('5.5')
    if trial:
        shutil.copytree(trial, entrant)
        for path in trial.parent.iterdir():
            if path.is_file() and path.name not in ('assets.txt', 'README.md', 'results.md'):
                shutil.copy(path, entrant / path.name)
        for name in (trial.parent / 'assets.txt').read_text(encoding='utf-8').split():
            (entrant / 'assets' / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(WARDENS / 'assets' / name, entrant / 'assets' / name)
        brief = (entrant / 'brief.md').read_text(encoding='utf-8')
        (entrant / 'brief.md').write_text(brief.replace('{DIR}', str(entrant)), encoding='utf-8')
        with open(entrant / 'build.hxml', 'a', encoding='utf-8') as f:
            f.write(f'-D helix-company=helix-trials\n-D helix-product={entrant.name}\n')
        (entrant / 'docs/include').mkdir(parents=True)
        for header in ('src/raylib.h', 'src/raymath.h', 'src/rlgl.h'):
            shutil.copy(raylib / header, entrant / 'docs/include')
        shutil.copytree(raylib / 'examples', entrant / 'docs/examples')
        return
    entrant.mkdir(parents=True)
    own = WARDENS / ('page' if page else 'native' if engine == 'helix' else 'native-c')
    brief = brief_of(game, own.name, 'brief-extras.md' if extras and not page else 'brief.md')
    (entrant / 'brief.md').write_text(brief.replace('{DIR}', str(entrant)), encoding='utf-8')
    for name in ('build.hxml', 'index.html', 'run.cjs') if page else ('build.hxml',) if engine == 'helix' else ('CMakeLists.txt',):
        shutil.copy(own / name, entrant / name)
    if engine == 'helix':
        with open(entrant / 'build.hxml', 'a', encoding='utf-8') as f:
            f.write(f'-D helix-company=helix-trials\n-D helix-product={entrant.name}\n')
    game_files(entrant, game)
    include = entrant / ('include' if engine == 'c' else 'docs/include')
    include.mkdir(parents=True)
    for header in ('src/raylib.h', 'src/raymath.h', 'src/rlgl.h', 'examples/shapes/raygui.h', 'examples/shaders/rlights.h'):
        shutil.copy(raylib / header, include)
    if engine == 'c':
        (entrant / 'lib').mkdir()
        shutil.copy(raylib / 'src/libraylib.a', entrant / 'lib')
    shutil.copytree(raylib / 'examples', entrant / 'docs/examples')
    if extras:
        (entrant / 'docs/extras').mkdir()
        for page in sorted(extras.glob('extras-*.md')):
            shutil.copy(page, entrant / 'docs/extras' / page.name)
        index = (extras / 'README.md').read_text(encoding='utf-8')
        listed = index[index.index('- `helix.raylib.extras`'):].split('\n\n', 1)[0]
        (entrant / 'docs/extras/README.md').write_text('# helix.raylib.extras\n\n' + listed + '\n', encoding='utf-8')
        # Each extra's example program, as engines/raylib/examples/extras/<extra>/Main.hx.
        for main in sorted((extras.parent / 'examples/extras').glob('*/Main.hx')):
            (entrant / 'docs/extras/examples' / main.parent.name).mkdir(parents=True)
            shutil.copy(main, entrant / 'docs/extras/examples' / main.parent.name / 'Main.hx')

def playwright(helix):
    """Playwright's package: HELIX_PLAYWRIGHT's, else the checkout's tools'."""
    return Path(os.environ.get('HELIX_PLAYWRIGHT', helix / 'build/tools/node_modules/playwright'))

def environment(entrant, helix, display):
    """The entrant's environment: the private display's, with the native build's settings and no sound, D-Bus or parent session."""
    import native_build
    import sdl3
    env = native_build.env(sdl3.find())
    for k in ('DISPLAY', 'SDL_VIDEO_DRIVER'):
        env[k] = display[k]
    for k in ('XAUTHORITY', 'WAYLAND_DISPLAY', 'DBUS_SESSION_BUS_ADDRESS', 'NODE_EXTRA_CA_CERTS') + CLAUDE_VARS:
        env.pop(k, None)
    home = entrant.parent / '.home' / entrant.name
    # A run.cjs (a three.js entrant's, or --page's): Playwright and its browsers, read-only in the sandbox.
    env.update(HELIX_PLAYWRIGHT=str(playwright(helix)), PLAYWRIGHT_BROWSERS_PATH=str(PLAYWRIGHT_BROWSERS))
    env.update(HAXELIB_PATH=str(helix / 'build/haxelib'), HXCPP_COMPILE_THREADS='4', SDL_AUDIO_DRIVER='dummy',
               XDG_DATA_HOME=str(home / 'data'), XDG_CACHE_HOME=str(home / 'cache'))
    (home / 'data').mkdir(parents=True, exist_ok=True)
    # raylib C plays through miniaudio, which SDL's dummy driver doesn't reach: it finds no PulseAudio server, and ALSA's default is null.
    alsa = home / 'alsa.conf'
    alsa.write_text('pcm.!default { type null }\n', encoding='utf-8')
    env.update(PULSE_SERVER='unix:/nonexistent', ALSA_CONFIG_PATH=str(alsa))
    # The shader tools the platform fetches into the cache are shared, so an entrant's first build doesn't fetch them again.
    tools = home / 'cache/helix/tools'
    if not tools.exists():
        tools.parent.mkdir(parents=True, exist_ok=True)
        tools.symlink_to(Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'helix/tools')
    return env

def sandbox(entrant, helix, claude_json):
    """bubblewrap's arguments for the entrant's sandbox; claude_json is ~/.claude.json open for reading, copied into its home."""
    home = Path.home()
    args = ['bwrap', '--ro-bind', '/', '/', '--dev', '/dev', '--proc', '/proc', '--tmpfs', '/tmp', '--ro-bind', '/tmp/.X11-unix',
            '/tmp/.X11-unix', '--tmpfs', f'/run/user/{os.getuid()}', '--tmpfs', str(home)]
    for path in (home / '.local/bin', home / '.local/share/claude', home / 'toolchains', home / '.cache/helix/tools', PLAYWRIGHT_BROWSERS,
                 playwright(helix).parent, helix):
        if path.exists():
            args += ['--ro-bind', str(path), str(path)]
    for path in (home / '.claude', helix / 'build', entrant, entrant.parent / '.home' / entrant.name):
        args += ['--bind', str(path), str(path)]
    return args + ['--file', str(claude_json.fileno()), str(home / '.claude.json'), '--unshare-pid', '--die-with-parent',
                   '--chdir', str(entrant), '--']

def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('entrant', type=Path)
    parser.add_argument('--helix', type=Path, required=True)
    parser.add_argument('--engine', choices=('helix', 'c', 'three'), default='helix')
    parser.add_argument('--model', default='sonnet')
    parser.add_argument('--hours', type=float, default=3)
    parser.add_argument('--trial', type=Path)
    parser.add_argument('--extras', action='store_true')
    parser.add_argument('--game', type=Path, default=WARDENS)
    parser.add_argument('--page', action='store_true')
    parser.add_argument('--command')
    args = parser.parse_args()
    entrant = args.entrant.resolve()
    helix = args.helix.resolve()
    if not (helix / 'build/haxelib').is_dir():
        sys.exit(f'run_entrant: {helix} has no build/haxelib; make it first (python3 helix.py test does)')
    sys.path.insert(0, str(helix / 'tools'))
    from private_display import private_display
    probe = entrant if entrant.exists() else entrant.parent
    if subprocess.run(['git', '-C', str(probe), 'rev-parse'], capture_output=True).returncode == 0:
        sys.exit(f'run_entrant: {entrant} is inside a git repository, whose commit messages the entrant would read')
    if not entrant.exists():
        if args.extras and args.engine != 'helix':
            sys.exit('run_entrant: --extras is for a helix-raylib entrant')
        if not (args.game / 'spec.md').exists():
            sys.exit(f'run_entrant: {args.game} has no spec.md')
        if args.page and (args.engine != 'helix' or args.trial):
            sys.exit('run_entrant: --page is for a helix-raylib entrant of a game')
        make(entrant, args.engine, args.trial.resolve() if args.trial else None,
             helix / 'engines/raylib/api' if args.extras or args.page else None, args.game.resolve(), args.page)
    elif not args.command:
        sys.exit(f'run_entrant: {entrant} is there already; an entrant starts from a directory of its own')

    with private_display() as display:
        env = environment(entrant, helix, display)
        with open(Path.home() / '.claude.json', 'rb') as claude_json:
            wrap = sandbox(entrant, helix, claude_json)
            fds = (claude_json.fileno(),)
            if args.command:
                sys.exit(subprocess.run(wrap + ['bash', '-c', args.command], env=env, pass_fds=fds).returncode)
            log(entrant, 'start')
            brief = (entrant / 'brief.md').read_text(encoding='utf-8')
            command = ['claude', '-p', brief, '--model', args.model, '--output-format', 'json',
                       '--allowedTools', 'Bash,Read,Write,Edit,Glob,Grep']
            with open(entrant / 'result.json', 'w') as out, open(entrant / 'stderr.log', 'w') as err:
                try:
                    code = subprocess.run(wrap + command, env=env, stdout=out, stderr=err, pass_fds=fds,
                                          timeout=args.hours * 3600).returncode
                except subprocess.TimeoutExpired:
                    code = 'timeout'
            log(entrant, f'end exit {code}')

if __name__ == '__main__':
    main()
