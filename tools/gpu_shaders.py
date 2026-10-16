"""SDL_GPU's shader dialects from a program's GLSL 410 (sokol-shdc's, with its layout): SPIR-V for Vulkan, MSL for Metal and HLSL (shader
model 5.1) for Direct3D 12, each laid out as SDL_GPU binds resources. Metal compiles the MSL and Direct3D 12 the HLSL (as DXBC, through the
system's d3dcompiler) when the program is made, so packing needs no Apple or Microsoft tool and gives the same output on every system.

The GLSL is rewritten for Vulkan before compiling: version 450; each uniform block (a vec4 array, as sokol-shdc flattens it) a std140 block,
and each texture a combined sampler, at SDL_GPU's sets (vertex textures 0, vertex blocks 1, fragment textures 2, fragment blocks 3), numbered
from 0 by slot within each; GL's clip depth (-1..1) moved to SDL_GPU's (0..1) after the vertex stage's main; gl_VertexID as gl_VertexIndex.
glslang compiles it to SPIR-V and SPIRV-Cross translates that to MSL (each resource at its binding) and HLSL (register(xN, spaceS), SDL_GPU's).

The tools, pinned in dependencies.json (gpuShaders) and kept in build/deps: glslang's official release for the system, checked against its
SHA-256; SPIRV-Cross's source release, checked, built once by hxcpp with the system's compiler (it publishes no programs).

    python3 tools/gpu_shaders.py      # fetches and builds the tools, and says where they are

    import gpu_shaders
    gpu_shaders.translate(vertex, fragment, blocks, textures)   # {'spirv': {...}, 'msl': {...}, 'hlsl': {...}}

Standard library only."""
import base64
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPS = ROOT / 'build' / 'deps'
sys.path.insert(0, str(ROOT / 'tools'))
from sdl3 import fetch  # noqa: E402


def pin():
    """dependencies.json's gpuShaders entry."""
    return json.loads((ROOT / 'dependencies.json').read_text(encoding='utf-8'))['gpuShaders']


def system():
    """This system's key in the glslang pin: linux, windows or macos (a universal program)."""
    if sys.platform == 'win32':
        return 'windows'
    if sys.platform == 'darwin':
        return 'macos'
    if platform.machine().lower() not in ('x86_64', 'amd64'):
        raise RuntimeError('gpu_shaders: glslang publishes Linux programs for x86_64 only')
    return 'linux'


def glslang():
    """glslang's program, its pinned release unpacked into build/deps the first time."""
    entry = pin()['glslang']
    folder = DEPS / f'glslang-{entry["version"]}-{system()}'
    program = folder / 'bin' / ('glslang.exe' if sys.platform == 'win32' else 'glslang')
    if not program.is_file():
        archive = fetch(entry[system()])
        shutil.rmtree(folder, ignore_errors=True)
        with zipfile.ZipFile(archive) as z:
            z.extractall(folder)
        if sys.platform != 'win32':
            program.chmod(0o755)
    return program


def spirv_cross():
    """SPIRV-Cross's program, built once from its pinned source into build/deps by hxcpp (the compiler HeliX's native builds use)."""
    entry = pin()['spirvCross']
    folder = DEPS / f'spirv-cross-{entry["version"]}'
    program = folder / ('spirv-cross.exe' if sys.platform == 'win32' else 'spirv-cross')
    if program.is_file():
        return program
    from pins import check_hxcpp
    from native_build import ARCH
    check_hxcpp()
    archive = fetch(entry)
    source = DEPS / f'spirv-cross-{entry["version"]}-source'
    shutil.rmtree(source, ignore_errors=True)
    with tarfile.open(archive) as tar:
        tar.extractall(source, filter='data')
    source = next(source.iterdir())
    files = ''.join(f'  <file name="{name}"/>\n' for name in ['main.cpp'] + sorted(p.name for p in source.glob('spirv_*.cpp')))
    build = source / 'Build.xml'
    build.write_text(f'''<xml>
 <include name="${{HXCPP}}/build-tool/BuildCommon.xml"/>
 <files id="spirv-cross" dir="{source.as_posix()}">
  <compilerflag value="-std=c++14" unless="windows"/>
  <compilerflag value="-EHsc" if="windows"/>
  <compilerflag value="-O2"/>
{files} </files>
 <target id="default" tool="linker" toolid="exe" output="spirv-cross">
  <outdir name="{folder.as_posix()}"/>
  <files id="spirv-cross"/>
 </target>
</xml>
''', encoding='utf-8')
    print(f'gpu_shaders: building SPIRV-Cross {entry["version"]} into {folder.relative_to(ROOT).as_posix()} (once)', flush=True)
    folder.mkdir(parents=True, exist_ok=True)
    subprocess.run(['haxelib', 'run', 'hxcpp', 'Build.xml', f'-D{ARCH}', f'-DHXCPP_COMPILE_THREADS={os.cpu_count() or 4}'], cwd=source,
                   check=True)
    shutil.rmtree(source.parent)
    if not program.is_file():
        raise RuntimeError(f'gpu_shaders: SPIRV-Cross built, but {program} is missing')
    return program


# SDL_GPU's descriptor sets: (textures, uniform blocks) by stage.
SETS = {'vertex': (0, 1), 'fragment': (2, 3)}


def vulkan_glsl(source, stage, blocks, textures):
    """A stage's GLSL 410 rewritten as SDL_GPU's Vulkan GLSL 450 (see the module's description). blocks and textures are the program's,
    as ShaderSource lists them; every uniform the stage declares must be one of them."""
    texture_set, block_set = SETS[stage]
    own_blocks = sorted((b for b in blocks if b['stage'] == stage), key=lambda b: b['slot'])
    own_textures = sorted((t for t in textures if t['stage'] == stage), key=lambda t: t['slot'])
    block_binding = {b['glslName']: i for i, b in enumerate(own_blocks)}
    texture_binding = {t['glslName']: i for i, t in enumerate(own_textures)}
    out = []
    for line in source.splitlines():
        if line.startswith('#version'):
            out.append('#version 450')
            continue
        uniform = re.fullmatch(r'uniform (\w+) (\w+)(\[\d+\])?;', line.strip())
        if uniform:
            kind, name, count = uniform.groups()
            if kind == 'vec4' and count and name in block_binding:
                out.append(f'layout(set = {block_set}, binding = {block_binding[name]}, std140) uniform {name}_block {{ vec4 {name}{count}; }};')
            elif kind.startswith('sampler') and not count and name in texture_binding:
                out.append(f'layout(set = {texture_set}, binding = {texture_binding[name]}) uniform {kind} {name};')
            else:
                raise ValueError(f'gpu_shaders: a uniform the layout doesn\'t list: {line.strip()}')
            continue
        if line.lstrip().startswith('uniform '):
            raise ValueError(f'gpu_shaders: an unexpected uniform declaration: {line.strip()}')
        out.append(line)
    text = '\n'.join(out) + '\n'
    text = re.sub(r'\bgl_VertexID\b', 'gl_VertexIndex', text)
    text = re.sub(r'\bgl_InstanceID\b', 'gl_InstanceIndex', text)
    if stage == 'vertex':
        if len(re.findall(r'\bvoid main\(\)', text)) != 1:
            raise ValueError('gpu_shaders: expected one main in the vertex stage')
        text = re.sub(r'\bvoid main\(\)', 'void helix_main()', text)
        text += '\n// GL\'s clip depth (-1..1) as SDL_GPU\'s (0..1).\nvoid main()\n{\n    helix_main();\n    gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5;\n}\n'
    return text


def translate(vertex, fragment, blocks, textures):
    """A program's GLSL 410 stages in SDL_GPU's dialects: {'spirv': {'vertex', 'fragment'} as base64, 'msl' and 'hlsl': {'vertex', 'fragment'}
    as text}. MSL's entry points are main0, HLSL's main."""
    compiler, cross = glslang(), spirv_cross()
    result = {'spirv': {}, 'msl': {}, 'hlsl': {}}
    with tempfile.TemporaryDirectory() as temporary:
        folder = Path(temporary)
        for stage, source in (('vertex', vertex), ('fragment', fragment)):
            suffix = 'vert' if stage == 'vertex' else 'frag'
            glsl = folder / f'{stage}.{suffix}'
            spirv = folder / f'{stage}.spv'
            glsl.write_text(vulkan_glsl(source, stage, blocks, textures), encoding='utf-8')
            run = subprocess.run([str(compiler), '-V', '--target-env', 'vulkan1.0', '-o', str(spirv), str(glsl)], capture_output=True, text=True)
            if run.returncode != 0:
                raise RuntimeError(f'gpu_shaders: glslang refused the {stage} stage:\n{run.stdout}{run.stderr}\n{glsl.read_text()}')
            result['spirv'][stage] = base64.b64encode(spirv.read_bytes()).decode('ascii')
            result['msl'][stage] = subprocess.run([str(cross), str(spirv), '--msl', '--msl-version', '20100', '--msl-decoration-binding'],
                                                  capture_output=True, text=True, check=True).stdout
            result['hlsl'][stage] = subprocess.run([str(cross), str(spirv), '--hlsl', '--shader-model', '51'],
                                                   capture_output=True, text=True, check=True).stdout
    return result


def tool_stamp():
    """When the dialects' translation last changed: this file's, and the pins'."""
    return max(Path(__file__).stat().st_mtime, (ROOT / 'dependencies.json').stat().st_mtime)


if __name__ == '__main__':
    print(f'gpu_shaders: glslang {glslang()}')
    print(f'gpu_shaders: spirv-cross {spirv_cross()}')
