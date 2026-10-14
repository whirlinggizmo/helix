"""Pack an app's shader (.glsl) into a HeliX shader file (.hxshader): JSON holding its program for every graphics backend HeliX has (GLSL 410
natively, GLSL ES 300 in the browser), compiled by sokol-shdc, and what the program needs bound (attributes, uniform blocks and their members,
textures). Programs load it as any asset (helix.graphics.Shaders) and the adapters build the program from it at run time.

A shader is a fragment stage `@fs fs` that includes one framework block, which decides its kind and supplies the rest:

    @include_block helix_screen   a screen effect: drawn over a whole finished frame (helix.graphics.ScreenEffect)

Its own parameters are uniform blocks at binding 2 and up (float, vec2, vec3, vec4 and mat4 members, and arrays of vec4 and mat4), set by name; its own
textures are at binding 1 and up, each with a sampler at the same binding. Uniform blocks 0 and 1 and texture 0 are the framework's.

    python3 tools/pack_shader.py [--shdc path] input.glsl output.hxshader"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import yaml

ROOT = Path(__file__).resolve().parents[1]
FORMAT = 1

# The framework's half of each kind: its vertex stage, and the block the app's fragment stage includes.
KINDS = {
    'helix_screen': '''
@vs helix_screen_vs
// The adapter's: clip space's x and y scales (y is -1 in a pass drawn flipped, into a render target on GL).
layout(binding=0) uniform helix_screen_vs_params {
    vec4 helix_clip;
};
out vec2 helix_screen_uv;
void main() {
    // One triangle over the whole viewport; uv 0, 0 is the frame's top left.
    vec2 p = vec2(float((gl_VertexIndex << 1) & 2), float(gl_VertexIndex & 2)) * 2.0 - 1.0;
    helix_screen_uv = vec2(p.x + 1.0, 1.0 - p.y) * 0.5;
    gl_Position = vec4(p.x, p.y * helix_clip.y, 0.0, 1.0);
}
@end

@block helix_screen
// The frame being drawn over (its color values as the framebuffer holds them, sRGB), its size and the time.
layout(binding=1) uniform helix_screen_params {
    vec4 helix_screen_info; // xy the frame's size in pixels, z seconds since the effect began
};
layout(binding=0) uniform texture2D helix_screen_texture;
layout(binding=0) uniform sampler helix_screen_sampler;
in vec2 helix_screen_uv;
out vec4 helix_frag_color;
// The frame's color here.
vec4 helix_screen_color() { return texture(sampler2D(helix_screen_texture, helix_screen_sampler), helix_screen_uv); }
// The frame's color at uv (0, 0 its top left).
vec4 helix_screen_color_at(vec2 uv) { return texture(sampler2D(helix_screen_texture, helix_screen_sampler), uv); }
vec2 helix_screen_size() { return helix_screen_info.xy; }
float helix_time() { return helix_screen_info.z; }
void helix_output(vec3 color, float alpha) { helix_frag_color = vec4(color, alpha); }
@end
''',
}
VERTEX = {'helix_screen': 'helix_screen_vs'}
ATTRIBUTES = {'helix_screen': []}

# std140: each member's size and alignment in bytes; an array's elements are each 16 aligned.
TYPES = {'float': (4, 4), 'vec2': (8, 8), 'vec3': (12, 16), 'vec4': (16, 16), 'mat4': (64, 16)}


def fail(message):
    sys.exit(f'pack_shader: {message}')


def members(source, block):
    """The members of uniform block `block` in the app's source, with their std140 offsets: name, type, offset, count (1 unless an array)."""
    match = re.search(r'uniform\s+' + block + r'\s*\{(.*?)\}', source, re.S)
    if not match:
        fail(f'uniform block {block} not found in the source')
    body = re.sub(r'//[^\n]*|/\*.*?\*/', '', match.group(1), flags=re.S)
    out, offset = [], 0
    for declaration in filter(None, (d.strip() for d in body.split(';'))):
        found = re.fullmatch(r'(\w+)\s+(\w+)(?:\s*\[\s*(\d+)\s*\])?', declaration)
        if not found or found.group(1) not in TYPES:
            fail(f'unsupported member in {block}: {declaration!r} (float, vec2, vec3, vec4, mat4, and arrays of vec4 and mat4)')
        kind, name, count = found.group(1), found.group(2), int(found.group(3) or 1)
        if found.group(3) and kind not in ('vec4', 'mat4'):
            fail(f'{block}: {name} is an array of {kind}; arrays must be of vec4 or mat4 (sokol-shdc\'s rule)')
        size, align = TYPES[kind]
        if found.group(3):
            align, size = 16, 16 * count if kind != 'mat4' else 64 * count
        offset = (offset + align - 1) // align * align
        out.append({'name': name, 'type': kind, 'offset': offset, 'count': count})
        offset += size
    return out


def pack(shdc, source_path, output_path):
    source = Path(source_path).read_text()
    kinds = [k for k in KINDS if re.search(r'@include_block\s+' + k + r'\b', source)]
    if len(kinds) != 1:
        fail(f'{source_path}: include exactly one framework block ({", ".join(KINDS)})')
    if not re.search(r'@fs\s+fs\b', source):
        fail(f'{source_path}: the fragment stage must be "@fs fs"')
    kind = kinds[0]
    program = 'shader'
    full = KINDS[kind] + '\n' + source + f'\n@program {program} {VERTEX[kind]} fs\n'
    with tempfile.TemporaryDirectory() as scratch:
        scratch = Path(scratch)
        (scratch / 'shader.glsl').write_text(full)
        for args in (['-o', scratch / 'shader.h'], ['-o', scratch / 'shader', '-f', 'bare_yaml']):
            done = subprocess.run([shdc, '-i', scratch / 'shader.glsl', *args, '-l', 'glsl410:glsl300es', '--no-log-cmdline'],
                                  capture_output=True, text=True)
            if done.returncode:
                fail(f'{source_path}: sokol-shdc failed\n{done.stdout}{done.stderr}'.replace(str(scratch / 'shader.glsl'), str(source_path)))
        reflection = yaml.safe_load((scratch / 'shader_reflection.yaml').read_text())
        dialects, first = {}, None
        for entry in reflection['shaders']:
            p = entry['programs'][0]
            dialects[entry['slang']] = {'vertex': Path(p['vertex_func']['path']).read_text(),
                                        'fragment': Path(p['fragment_func']['path']).read_text()}
            first = first or p
    p = first
    blocks = []
    for b in p.get('uniform_blocks') or []:
        uniforms = b['glsl_uniforms']
        if len(uniforms) != 1 or uniforms[0]['type'] != 'vec4':
            fail(f'{source_path}: uniform block {b["struct_name"]} must flatten to one vec4 array')
        block = {'slot': b['slot'], 'stage': b['stage'], 'size': b['size'], 'glslName': uniforms[0]['glsl_name'],
                 'vec4s': uniforms[0]['array_count'], 'name': b['struct_name']}
        if b['struct_name'].startswith('helix_'):
            require_slot = b['slot'] < 2
        else:
            require_slot = b['slot'] >= 2
            block['members'] = members(source, b['struct_name'])
        if not require_slot:
            fail(f'{source_path}: uniform blocks 0 and 1 are the framework\'s; give {b["struct_name"]} binding 2 or more')
        blocks.append(block)
    textures = []
    views = {v['texture']['slot']: v['texture'] for v in p.get('views') or []}
    for pair in p.get('texture_sampler_pairs') or []:
        if pair['view_slot'] != pair['sampler_slot']:
            fail(f'{source_path}: texture {pair["view_name"]} and its sampler must share a binding')
        textures.append({'slot': pair['view_slot'], 'stage': pair['stage'], 'name': pair['view_name'], 'glslName': pair['glsl_name']})
    if set(views) != {t['slot'] for t in textures}:
        fail(f'{source_path}: every texture needs a sampler')
    shader = {'helixShader': FORMAT, 'kind': kind.removeprefix('helix_'), 'attributes': ATTRIBUTES[kind], 'glsl410': dialects['glsl410'],
              'glsl300es': dialects['glsl300es'], 'uniformBlocks': sorted(blocks, key=lambda b: b['slot']),
              'textures': sorted(textures, key=lambda t: t['slot'])}
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    Path(output_path).write_text(json.dumps(shader, indent=1) + '\n')


def shdc_path(given=None):
    """The pinned sokol-shdc: given, or the one the shader generation remembered."""
    remembered = ROOT / 'build/generated/shdc-path.txt'
    path = given or (remembered.read_text().strip() if remembered.is_file() else None)
    if not path:
        fail('pass --shdc /path/to/pinned/sokol-shdc')
    return path


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--shdc')
    parser.add_argument('input')
    parser.add_argument('output')
    a = parser.parse_args()
    pack(shdc_path(a.shdc), a.input, a.output)
