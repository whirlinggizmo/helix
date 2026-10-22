"""The shader packer, sokol-shdc and SDL_GPU's translators as the repository's Python tools reach them: src/helix/tool/shader/ShaderTool.hx, in Haxe
(helix.tool.Build.packShaders and Watchers.watchShaders run the same code), run by Haxe's interpreter in the checkout. A refusal (a shader
the packer won't take, a tool that can't be had) exits with its message, as the packer's own refusals did.

    import shader_tool
    shader_tool.pack([(source, output), ...], sdl_gpu=False)
    shader_tool.pack_library(out, gpu_out=None, sources=None)   # the stems packed
    shader_tool.translate([{'vertex', 'fragment', 'blocks', 'textures'}, ...])   # SDL_GPU's dialects of each
    shader_tool.shdc_path()

Standard library only."""
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
# The Haxe the tool is: a change to any of it means what it packed may be stale.
SOURCES = (ROOT / 'src/helix/tool',)


def run(*args, stdin=None):
    """The tool run with args (and stdin's text): its standard output; its messages pass through; exits with its error when it refuses.
    SDL_GPU's dialects may build SPIRV-Cross with hxcpp, the repository's pinned one (tools/pins.py)."""
    if args[0] == 'translate' or '--sdl-gpu' in args or '--sdl-gpu-out' in args:
        sys.path.insert(0, str(ROOT / 'tools'))
        from pins import check_hxcpp
        check_hxcpp()
    done = subprocess.run(['haxe', '-cp', 'src', '--run', 'helix.tool.shader.ShaderTool', *map(str, args)], cwd=ROOT, input=stdin, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True, encoding='utf-8', env=dict(os.environ))
    if done.returncode:
        sys.exit(done.stderr.strip() or f'shader_tool: {args[0]} failed ({done.returncode})')
    if done.stderr:
        print(done.stderr, end='', file=sys.stderr, flush=True)
    return done.stdout


def pack(pairs, sdl_gpu=False):
    """Each (source .glsl, output .hxshader) of pairs packed, with SDL_GPU's dialects when sdl_gpu."""
    pairs = list(pairs)
    if pairs:
        run('pack', *(['--sdl-gpu'] if sdl_gpu else []), *(str(p) for pair in pairs for p in pair))


def pack_library(out, gpu_out=None, sources=None):
    """The shader library (src/helix/shader, or sources) packed into generated Haxe in out, SDL_GPU's dialects into gpu_out when given,
    each only when changed (src/helix/tool/shader/ShaderPacker.hx's packLibrary). Returns the stems packed."""
    args = ['library', out] + (['--sdl-gpu-out', gpu_out] if gpu_out else []) + (['--sources', sources] if sources else [])
    return json.loads(run(*args))


def translate(programs):
    """Each program's GLSL 410 stages ({'vertex', 'fragment', 'blocks', 'textures'}) in SDL_GPU's dialects: {'spirv', 'msl', 'hlsl'}, each
    {'vertex', 'fragment'}."""
    return json.loads(run('translate', stdin=json.dumps(programs)))


def shdc_path():
    """The pinned sokol-shdc, fetched the first time."""
    return Path(run('shdc').strip())


def stamp():
    """When the tool last changed: its newest source's time."""
    return max(p.stat().st_mtime for directory in SOURCES for p in directory.rglob('*') if p.is_file())
