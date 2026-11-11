#!/usr/bin/env python3
"""Runs one entrant of the native blind trial (../README.md): claude -p in its own directory, on a private display, with no sound.

    python3 run_entrant.py <entrant directory> --helix <checkout> [--engine helix|c] [--model sonnet] [--hours 3] [--command CMD]

The entrant directory is made, and must not be there yet unless --command is given, from the spec, assets/ and raylib 5.5's C examples
(docs/examples), with the engine's own files:
- helix (helix-raylib, in Haxe): native/brief.md as brief.md (its {DIR} the directory's path), native/build.hxml, and raylib 5.5's
  headers in docs/include.
- c (the control, raylib 5.5 in C): native-c/brief.md as brief.md, native-c/Makefile, raylib 5.5's headers in include/ and its desktop
  library as lib/libraylib.a.
raylib's files are copied from the release tools/raylib_parity.py fetches and builds. A directory inside a git repository is refused,
as the entrant would see its commit messages.

--helix names the checkout of helix the tools come from and, for helix-raylib, the entrant builds against: a worktree at the commit
being tried, its build/haxelib made. The entrant's environment carries hxcpp's and the platform's settings from it and its haxelib,
no sound (SDL_AUDIO_DRIVER=dummy for SDL; for raylib C's miniaudio, no PulseAudio server and an ALSA whose one device is null), no
session D-Bus (SDL_OpenURL would reach the desktop's browser), and data and cache directories of its own beside the entrant
(.home/<name>), so entrants running at once keep their saves apart. The JSON result (usage, cost, turns, duration) goes to result.json, stderr to stderr.log, the start and
end to run.log.

--command runs a shell command in the entrant's environment in place of claude, to check the harness."""
import argparse
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
# Claude Code's own session variables, so the entrant starts as a session of its own, not a child of the one starting it.
CLAUDE_VARS = ('CLAUDECODE', 'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_CODE_CHILD_SESSION', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_PID',
               'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'CLAUDE_CODE_BRIDGE_SESSION_ID',
               'CLAUDE_CODE_SESSION_ATTENDED', 'CLAUDE_CODE_EXECPATH', 'CLAUDE_EFFORT')

def log(entrant, line):
    with open(entrant / 'run.log', 'a', encoding='utf-8') as f:
        f.write(datetime.now().astimezone().isoformat(timespec='seconds') + ' ' + line + '\n')

def make(entrant, engine):
    """Makes the entrant's directory from the trial's files and raylib 5.5's."""
    import raylib_parity
    raylib = raylib_parity.raylib('5.5')
    entrant.mkdir(parents=True)
    own = HERE / ('native' if engine == 'helix' else 'native-c')
    brief = (own / 'brief.md').read_text(encoding='utf-8')
    (entrant / 'brief.md').write_text(brief.replace('{DIR}', str(entrant)), encoding='utf-8')
    for name in ('build.hxml',) if engine == 'helix' else ('Makefile',):
        shutil.copy(own / name, entrant / name)
    shutil.copy(HERE / 'spec.md', entrant / 'spec.md')
    shutil.copytree(HERE / 'assets', entrant / 'assets')
    include = entrant / ('docs/include' if engine == 'helix' else 'include')
    include.mkdir(parents=True)
    for header in ('src/raylib.h', 'src/raymath.h', 'src/rlgl.h', 'examples/shapes/raygui.h', 'examples/shaders/rlights.h'):
        shutil.copy(raylib / header, include)
    if engine == 'c':
        (entrant / 'lib').mkdir()
        shutil.copy(raylib / 'src/libraylib.a', entrant / 'lib')
    shutil.copytree(raylib / 'examples', entrant / 'docs/examples')

def environment(entrant, helix, display):
    """The entrant's environment: the private display's, with the native build's settings and no sound, D-Bus or parent session."""
    import native_build
    import sdl3
    env = native_build.env(sdl3.find())
    for k in ('DISPLAY', 'SDL_VIDEO_DRIVER'):
        env[k] = display[k]
    for k in ('XAUTHORITY', 'WAYLAND_DISPLAY', 'DBUS_SESSION_BUS_ADDRESS') + CLAUDE_VARS:
        env.pop(k, None)
    home = entrant.parent / '.home' / entrant.name
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

def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('entrant', type=Path)
    parser.add_argument('--helix', type=Path, required=True)
    parser.add_argument('--engine', choices=('helix', 'c'), default='helix')
    parser.add_argument('--model', default='sonnet')
    parser.add_argument('--hours', type=float, default=3)
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
        make(entrant, args.engine)
    elif not args.command:
        sys.exit(f'run_entrant: {entrant} is there already; an entrant starts from a directory of its own')

    with private_display() as display:
        env = environment(entrant, helix, display)
        if args.command:
            sys.exit(subprocess.run(['bash', '-c', args.command], cwd=entrant, env=env).returncode)
        log(entrant, 'start')
        brief = (entrant / 'brief.md').read_text(encoding='utf-8')
        command = ['claude', '-p', brief, '--model', args.model, '--output-format', 'json',
                   '--allowedTools', 'Bash,Read,Write,Edit,Glob,Grep']
        with open(entrant / 'result.json', 'w') as out, open(entrant / 'stderr.log', 'w') as err:
            try:
                code = subprocess.run(command, cwd=entrant, env=env, stdout=out, stderr=err, timeout=args.hours * 3600).returncode
            except subprocess.TimeoutExpired:
                code = 'timeout'
        log(entrant, f'end exit {code}')

if __name__ == '__main__':
    main()
