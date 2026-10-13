"""Parse sokol-shdc bare_yaml with PyYAML; generate the framework shaders' fixed ABI.

shaders.json lists each program: its packed vertex attributes (order and roles), whether it samples one
texture, and the bytes of its one vertex-stage uniform block (0 for none). Shader reflection describes inputs
and bindings, not CPU packing, so the manifest supplies that and the reflection must agree with it.
Unsupported shapes fail closed. No generated C/GLSL text is inspected to discover bindings or filenames.
Every program's headers are compiled into one C file, so its stages, uniform blocks and samplers need names of
their own: prefix them with the program's name (color3d_vs, color3d_params).
"""
import json
from pathlib import Path
import re
import yaml

COMPONENTS = {'vec2': 2, 'vec3': 3, 'vec4': 4}


class MetadataError(ValueError):
    pass


class UniqueLoader(yaml.SafeLoader):
    """Safe YAML parsing with duplicate mapping keys rejected, not overwritten."""


def unique_mapping(loader, node):
    mapping = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node)
        if not isinstance(key, str) or key in mapping:
            raise MetadataError(f'Invalid or duplicate YAML key: {key!r}')
        mapping[key] = loader.construct_object(value_node)
    return mapping


UniqueLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, unique_mapping)


def require(condition, message):
    if not condition:
        raise MetadataError(message)


def fields(value, required, optional=()):
    require(isinstance(value, dict), 'Expected a mapping')
    require(set(required) <= value.keys() <= set(required) | set(optional),
            f'Unsupported metadata fields: {list(value)}; required {required}')


def name(value):
    require(isinstance(value, str) and re.fullmatch(r'[A-Za-z_][A-Za-z_0-9]*', value),
            f'Unsupported identifier: {value!r}')
    return value


def slot(value, maximum):
    require(type(value) is int and 0 <= value < maximum, f'Invalid binding slot: {value!r}')
    return value


def class_name(program):
    """sprite2d -> Sprite2D: the program's name as a Haxe type, 2D/3D capitalized."""
    return re.sub(r'(\d)d', r'\1D', program[0].upper() + program[1:])


def normalize(program, spec):
    fields(program, ['name', 'vertex_func', 'fragment_func', 'attrs'], ['views', 'samplers', 'texture_sampler_pairs', 'uniform_blocks'])
    require(program['name'] == spec['program'], 'Unexpected shader program')
    for stage in ['vertex', 'fragment']:
        function = program[stage + '_func']
        fields(function, ['path', 'is_binary', 'entry_point'])
        require(isinstance(function['path'], str) and function['is_binary'] is False and
                function['entry_point'] == 'main', 'Expected GLSL source with main entry')
    attrs = program['attrs']
    require(isinstance(attrs, list) and len(attrs) == len(spec['attributes']), 'Unexpected vertex attributes')
    by_name = {}
    slots = set()
    for attr in attrs:
        fields(attr, ['slot', 'type', 'base_type', 'glsl_name'])
        ident = name(attr['glsl_name']); index = slot(attr['slot'], 16)
        require(ident not in by_name and index not in slots, 'Duplicate attribute name or slot')
        require(attr['base_type'] == 'Float', 'Only float vertex attributes are supported')
        by_name[ident] = attr; slots.add(index)
    packed = []; offset = 0
    for attribute in spec['attributes']:
        attr = by_name.get(attribute['name'])
        require(attr is not None and attr['type'] == attribute['type'], f'Vertex schema mismatch: {attribute["role"]}')
        components = COMPONENTS[attribute['type']]
        packed.append(dict(attribute, slot=attr['slot'], components=components, offset=offset))
        offset += components * 4
    contract = {'program': program['name'], 'stride': offset, 'attributes': packed, 'texture': None, 'uniforms': None}
    count = 1 if spec['texture'] else 0
    for key in ['views', 'samplers', 'texture_sampler_pairs']:
        require(isinstance(program.get(key, []), list) and len(program.get(key, [])) == count, f'Expected {count} {key} binding(s)')
    if count:
        view = program['views'][0]; fields(view, ['texture']); texture = view['texture']
        fields(texture, ['slot', 'stage', 'name', 'multisampled', 'type', 'sample_type'])
        require(texture['stage'] == 'fragment' and texture['multisampled'] is False and
                texture['type'] == '2d' and texture['sample_type'] == 'float', 'Unsupported texture')
        name(texture['name']); slot(texture['slot'], 32)
        sampler = program['samplers'][0]
        fields(sampler, ['slot', 'stage', 'name', 'sampler_type'])
        require(sampler['stage'] == 'fragment' and sampler['sampler_type'] == 'filtering', 'Unsupported sampler')
        name(sampler['name']); slot(sampler['slot'], 16)
        pair = program['texture_sampler_pairs'][0]
        fields(pair, ['slot', 'stage', 'name', 'view_name', 'sampler_name', 'view_slot', 'sampler_slot', 'glsl_name'])
        require(pair['stage'] == 'fragment' and pair['view_name'] == texture['name'] and
                pair['sampler_name'] == sampler['name'] and pair['view_slot'] == texture['slot'] and
                pair['sampler_slot'] == sampler['slot'], 'Inconsistent texture/sampler pair')
        name(pair['name']); name(pair['glsl_name']); slot(pair['slot'], 16)
        contract['texture'] = {'view': texture['slot'], 'viewName': texture['name'], 'sampler': sampler['slot'],
                               'samplerName': sampler['name'], 'textureUnit': pair['slot'], 'textureUniform': pair['glsl_name']}
    blocks = program.get('uniform_blocks', [])
    require(isinstance(blocks, list) and len(blocks) == (1 if spec['uniformBytes'] else 0), 'Unexpected uniform blocks')
    if blocks:
        block = blocks[0]
        fields(block, ['slot', 'stage', 'size', 'struct_name', 'inst_name', 'glsl_uniforms'])
        require(block['stage'] == 'vertex' and block['size'] == spec['uniformBytes'], 'Unexpected uniform block size or stage')
        name(block['struct_name']); slot(block['slot'], 8)
        require(isinstance(block['glsl_uniforms'], list) and len(block['glsl_uniforms']) == 1, 'Expected one flattened uniform array')
        flat = block['glsl_uniforms'][0]
        fields(flat, ['type', 'array_count', 'offset', 'glsl_name'])
        require(flat['type'] == 'vec4' and flat['offset'] == 0 and flat['array_count'] * 16 == block['size'], 'Unexpected uniform packing')
        contract['uniforms'] = {'uniformSlot': block['slot'], 'uniformBytes': block['size'], 'uniformBlock': block['struct_name'],
                                'uniformName': name(flat['glsl_name'])}
    return contract


def load_spec(spec):
    fields(spec, ['program', 'attributes', 'texture', 'uniformBytes']); name(spec['program'])
    require(isinstance(spec['attributes'], list) and spec['attributes'], 'Expected packed attributes')
    for attribute in spec['attributes']:
        fields(attribute, ['role', 'name', 'type']); name(attribute['role']); name(attribute['name'])
        require(attribute['type'] in COMPONENTS, 'Unsupported CPU vertex packing')
    require(len({a['name'] for a in spec['attributes']}) == len(spec['attributes']) and
            len({a['role'] for a in spec['attributes']}) == len(spec['attributes']), 'Duplicate vertex schema names or roles')
    require(isinstance(spec['texture'], bool), 'texture is true or false')
    require(type(spec['uniformBytes']) is int and spec['uniformBytes'] >= 0 and spec['uniformBytes'] % 16 == 0, 'uniformBytes is a multiple of 16')


def load_contract(metadata, spec):
    """One program's contract from its reflection; both GLSL dialects must agree."""
    load_spec(spec)
    document = yaml.load(Path(metadata).read_text(), Loader=UniqueLoader)
    fields(document, ['shaders'])
    require(isinstance(document['shaders'], list) and len(document['shaders']) == 2, 'Expected two shader dialects')
    programs = {}; contracts = []
    for shader in document['shaders']:
        fields(shader, ['slang', 'programs'])
        require(shader['slang'] in ['glsl410', 'glsl300es'] and shader['slang'] not in programs, 'Unexpected or duplicate dialect')
        require(isinstance(shader['programs'], list) and len(shader['programs']) == 1, 'Expected one shader program')
        program = shader['programs'][0]
        contracts.append(normalize(program, spec)); programs[shader['slang']] = program
    require(contracts[0] == contracts[1], 'Shader dialect binding layouts disagree')
    return contracts[0], programs


def manifest(path):
    """The programs listed in shaders.json, checked."""
    document = json.loads(Path(path).read_text())
    fields(document, ['programs'])
    require(isinstance(document['programs'], list) and document['programs'], 'Expected programs')
    for spec in document['programs']:
        load_spec(spec)
    require(len({spec['program'] for spec in document['programs']}) == len(document['programs']), 'Duplicate programs')
    return document['programs']


def generate(manifest_path, output, working_dir):
    """Writes each program's <Name>Layout.hx, GeneratedShader.hx (every program's GLSL ES source), shaders.h (the C layouts and
    binding slots) and shader-contract.json from output/<program>_reflection.yaml."""
    output = Path(output); working_dir = Path(working_dir)
    hx_shader = ['// Generated from structured shader reflection and shaders.json.', 'class GeneratedShader {']
    c = ['/* Generated from structured shader reflection and shaders.json. */', '#pragma once']
    contracts = []
    for spec in manifest(manifest_path):
        contract, programs = load_contract(output / f'{spec["program"]}_reflection.yaml', spec)
        program = contract['program']; upper = program.upper(); type_name = class_name(program) + 'Layout'
        for stage in ['vertex', 'fragment']:
            function = programs['glsl300es'][stage + '_func']
            path = (working_dir / function['path']).resolve()
            require(path.is_relative_to(output.resolve()), 'Shader source must be inside the generated directory')
            hx_shader.append(f' public static function {program}{stage.capitalize()}():String return {json.dumps(path.read_text())};')
        hx = [f'// Generated from structured shader reflection and shaders.json: the {program} program.', f'class {type_name} {{',
              f' public static inline var stride={contract["stride"]};']
        c += [f'#include "{program}.glsl.h"', f'#define HELIX_{upper}_SHADER_DESC {program}_shader_desc', f'#define HELIX_{upper}_STRIDE {contract["stride"]}']
        for key, value in (contract['texture'] or {}).items():
            if not key.endswith('Name'):hx.append(f' public static inline var {key}={json.dumps(value)};')
        if contract['texture']:
            t = contract['texture']
            c += [f'#define HELIX_{upper}_VIEW_SLOT {t["view"]}', f'#define HELIX_{upper}_SAMPLER_SLOT {t["sampler"]}',
                  f'_Static_assert(VIEW_{t["viewName"]} == HELIX_{upper}_VIEW_SLOT, "Shader view mismatch");',
                  f'_Static_assert(SMP_{t["samplerName"]} == HELIX_{upper}_SAMPLER_SLOT, "Shader sampler mismatch");']
        if contract['uniforms']:
            u = contract['uniforms']
            hx += [f' public static inline var uniformBytes={u["uniformBytes"]};', f' public static inline var uniformName={json.dumps(u["uniformName"])};']
            c += [f'#define HELIX_{upper}_UNIFORM_SLOT {u["uniformSlot"]}', f'#define HELIX_{upper}_UNIFORM_BYTES {u["uniformBytes"]}',
                  f'_Static_assert(UB_{u["uniformBlock"]} == HELIX_{upper}_UNIFORM_SLOT, "Uniform block mismatch");']
        c += [f'static sg_vertex_layout_state helix_{program}_layout(void) {{', ' sg_vertex_layout_state layout = {0};',
              f' layout.buffers[0].stride = HELIX_{upper}_STRIDE;']
        for attr in contract['attributes']:
            role = attr['role']
            for suffix, value in [('Slot', attr['slot']), ('Offset', attr['offset']), ('Components', attr['components']), ('Name', attr['name'])]:
                hx.append(f' public static inline var {role}{suffix}={json.dumps(value)};')
            c += [f' _Static_assert(ATTR_{program}_{attr["name"]} == {attr["slot"]}, "Shader attribute mismatch");',
                  f' layout.attrs[{attr["slot"]}].format = SG_VERTEXFORMAT_FLOAT{attr["components"]};',
                  f' layout.attrs[{attr["slot"]}].offset = {attr["offset"]};']
        hx.append('}'); c += [' return layout;', '}']
        (output / f'{type_name}.hx').write_text('\n'.join(hx) + '\n')
        contracts.append(contract)
    hx_shader.append('}')
    (output / 'GeneratedShader.hx').write_text('\n'.join(hx_shader) + '\n')
    (output / 'shaders.h').write_text('\n'.join(c) + '\n')
    (output / 'shader-contract.json').write_text(json.dumps(contracts, indent=2) + '\n')
    return contracts
