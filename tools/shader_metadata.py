"""Parse sokol-shdc bare_yaml with PyYAML; generate the framework shaders' fixed ABI.

shaders.json lists each program: its packed vertex attributes (order and roles; "instance": true puts one in the
second buffer, stepped once an instance), the textures it samples (each a role and its texture's name in the
GLSL, each with a sampler of its own; "depth_array": true for a layered depth texture read through a comparison
sampler, a shadow map; "cube": true for a cubemap), and its uniform blocks (at most one a stage, each its bytes). A program reading only some
of another's vertices gives each buffer's "stride" (and "offset" on an attribute that doesn't follow the last); one drawing a triangle from
its vertex index alone has no attributes. Shader reflection describes inputs
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
    fields(program, ['name', 'vertex_func', 'fragment_func'], ['attrs', 'views', 'samplers', 'texture_sampler_pairs', 'uniform_blocks'])
    require(program['name'] == spec['program'], 'Unexpected shader program')
    for stage in ['vertex', 'fragment']:
        function = program[stage + '_func']
        fields(function, ['path', 'is_binary', 'entry_point'])
        require(isinstance(function['path'], str) and function['is_binary'] is False and
                function['entry_point'] == 'main', 'Expected GLSL source with main entry')
    attrs = program.get('attrs', [])
    require(isinstance(attrs, list) and len(attrs) == len(spec['attributes']), 'Unexpected vertex attributes')
    by_name = {}
    slots = set()
    for attr in attrs:
        fields(attr, ['slot', 'type', 'base_type', 'glsl_name'])
        ident = name(attr['glsl_name']); index = slot(attr['slot'], 16)
        require(ident not in by_name and index not in slots, 'Duplicate attribute name or slot')
        require(attr['base_type'] == 'Float', 'Only float vertex attributes are supported')
        by_name[ident] = attr; slots.add(index)
    packed = []; offsets = [0, 0]
    for attribute in spec['attributes']:
        attr = by_name.get(attribute['name'])
        require(attr is not None and attr['type'] == attribute['type'], f'Vertex schema mismatch: {attribute["role"]}')
        components = COMPONENTS[attribute['type']]
        buffer = 1 if attribute.get('instance') else 0
        offset = attribute.get('offset', offsets[buffer])
        require(offset >= offsets[buffer], f'Overlapping attribute: {attribute["role"]}')
        packed.append({'role': attribute['role'], 'name': attribute['name'], 'type': attribute['type'], 'buffer': buffer, 'slot': attr['slot'],
                       'components': components, 'offset': offset})
        offsets[buffer] = offset + components * 4
    strides = [spec.get('stride', offsets[0]), spec.get('instanceStride', offsets[1])]
    require(strides[0] >= offsets[0] and strides[1] >= offsets[1], 'A stride shorter than its attributes')
    contract = {'program': program['name'], 'stride': strides[0], 'instanceStride': strides[1], 'attributes': packed, 'textures': [], 'uniforms': []}
    wanted = spec['textures']
    for key in ['views', 'samplers', 'texture_sampler_pairs']:
        require(isinstance(program.get(key, []), list) and len(program.get(key, [])) == len(wanted), f'Expected {len(wanted)} {key} binding(s)')
    contract['textures'] = []
    for want in wanted:
        views = [v for v in program.get('views', []) if isinstance(v, dict) and isinstance(v.get('texture'), dict) and v['texture'].get('name') == want['name']]
        require(len(views) == 1, f'Expected the texture {want["name"]}')
        fields(views[0], ['texture']); texture = views[0]['texture']
        fields(texture, ['slot', 'stage', 'name', 'multisampled', 'type', 'sample_type'])
        depth = want.get('depth_array', False); cube = want.get('cube', False)
        require(texture['stage'] == 'fragment' and texture['multisampled'] is False and
                (texture['type'], texture['sample_type']) == (('array', 'depth') if depth else ('cube', 'float') if cube else ('2d', 'float')),
                'Unsupported texture')
        slot(texture['slot'], 32)
        pairs = [p for p in program['texture_sampler_pairs'] if isinstance(p, dict) and p.get('view_name') == want['name']]
        require(len(pairs) == 1, f'Expected one sampler for {want["name"]}')
        pair = pairs[0]
        fields(pair, ['slot', 'stage', 'name', 'view_name', 'sampler_name', 'view_slot', 'sampler_slot', 'glsl_name'])
        samplers = [p for p in program['samplers'] if isinstance(p, dict) and p.get('name') == pair['sampler_name']]
        require(len(samplers) == 1, f'Expected the sampler {pair["sampler_name"]}')
        sampler = samplers[0]
        fields(sampler, ['slot', 'stage', 'name', 'sampler_type'])
        require(sampler['stage'] == 'fragment' and sampler['sampler_type'] == ('comparison' if depth else 'filtering'), 'Unsupported sampler')
        name(sampler['name']); slot(sampler['slot'], 16)
        require(pair['stage'] == 'fragment' and pair['view_slot'] == texture['slot'] and pair['sampler_slot'] == sampler['slot'],
                'Inconsistent texture/sampler pair')
        name(pair['name']); name(pair['glsl_name']); slot(pair['slot'], 16)
        contract['textures'].append({'role': want['role'], 'depthArray': depth, 'cube': cube, 'view': texture['slot'], 'viewName': texture['name'], 'sampler': sampler['slot'],
                                     'samplerName': sampler['name'], 'unit': pair['slot'], 'uniform': pair['glsl_name']})
    blocks = program.get('uniform_blocks', [])
    require(isinstance(blocks, list) and len(blocks) == len(spec['uniforms']), 'Unexpected uniform blocks')
    for want in spec['uniforms']:
        found = [b for b in blocks if isinstance(b, dict) and b.get('stage') == want['stage']]
        require(len(found) == 1, f'Expected one {want["stage"]} uniform block')
        block = found[0]
        fields(block, ['slot', 'stage', 'size', 'struct_name', 'inst_name', 'glsl_uniforms'])
        require(block['size'] == want['bytes'], f'Unexpected uniform block size: {block["size"]}, not {want["bytes"]}')
        name(block['struct_name']); slot(block['slot'], 8)
        require(isinstance(block['glsl_uniforms'], list) and len(block['glsl_uniforms']) == 1, 'Expected one flattened uniform array')
        flat = block['glsl_uniforms'][0]
        fields(flat, ['type', 'array_count', 'offset', 'glsl_name'])
        require(flat['type'] == 'vec4' and flat['offset'] == 0 and flat['array_count'] * 16 == block['size'], 'Unexpected uniform packing')
        contract['uniforms'].append({'stage': want['stage'], 'slot': block['slot'], 'bytes': block['size'], 'block': block['struct_name'],
                                     'name': name(flat['glsl_name'])})
    return contract


def load_spec(spec):
    fields(spec, ['program', 'attributes', 'textures', 'uniforms'], ['stride', 'instanceStride']); name(spec['program'])
    for key in ['stride', 'instanceStride']:
        require(key not in spec or type(spec[key]) is int and spec[key] > 0 and spec[key] % 4 == 0, f'{key} is a positive multiple of 4')
    require(isinstance(spec['attributes'], list), 'Expected packed attributes')
    for attribute in spec['attributes']:
        fields(attribute, ['role', 'name', 'type'], ['instance', 'offset']); name(attribute['role']); name(attribute['name'])
        require('offset' not in attribute or type(attribute['offset']) is int and attribute['offset'] >= 0 and attribute['offset'] % 4 == 0,
                'An offset is a multiple of 4')
        require(attribute['type'] in COMPONENTS, 'Unsupported CPU vertex packing')
        require(attribute.get('instance', False) in (True, False), 'instance is true or false')
    require(len({a['name'] for a in spec['attributes']}) == len(spec['attributes']) and
            len({a['role'] for a in spec['attributes']}) == len(spec['attributes']), 'Duplicate vertex schema names or roles')
    require(isinstance(spec['textures'], list), 'textures is a list')
    for texture in spec['textures']:
        fields(texture, ['role', 'name'], ['depth_array', 'cube']); name(texture['role']); name(texture['name'])
        require(texture.get('depth_array', False) in (True, False) and texture.get('cube', False) in (True, False) and
                not (texture.get('depth_array') and texture.get('cube')), 'depth_array and cube are true or false, not both')
    require(len({t['role'] for t in spec['textures']}) == len(spec['textures']), 'Duplicate texture roles')
    require(isinstance(spec['uniforms'], list), 'uniforms is a list')
    for block in spec['uniforms']:
        fields(block, ['stage', 'bytes'])
        require(block['stage'] in ('vertex', 'fragment') and type(block['bytes']) is int and block['bytes'] > 0 and block['bytes'] % 16 == 0,
                'A uniform block is a stage and a positive multiple of 16 bytes')
    require(len({b['stage'] for b in spec['uniforms']}) == len(spec['uniforms']), 'One uniform block a stage')


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
              f' public static inline var stride={contract["stride"]};', f' public static inline var instanceStride={contract["instanceStride"]};']
        c += [f'#include "{program}.glsl.h"', f'#define HELIX_{upper}_SHADER_DESC {program}_shader_desc', f'#define HELIX_{upper}_STRIDE {contract["stride"]}',
              f'#define HELIX_{upper}_INSTANCE_STRIDE {contract["instanceStride"]}']
        for t in contract['textures']:
            role = t['role']; ROLE = role.upper()
            hx += [f' public static inline var {role}Unit={t["unit"]};', f' public static inline var {role}Uniform={json.dumps(t["uniform"])};']
            c += [f'#define HELIX_{upper}_{ROLE}_VIEW_SLOT {t["view"]}', f'#define HELIX_{upper}_{ROLE}_SAMPLER_SLOT {t["sampler"]}',
                  f'_Static_assert(VIEW_{t["viewName"]} == HELIX_{upper}_{ROLE}_VIEW_SLOT, "Shader view mismatch");',
                  f'_Static_assert(SMP_{t["samplerName"]} == HELIX_{upper}_{ROLE}_SAMPLER_SLOT, "Shader sampler mismatch");']
        for u in contract['uniforms']:
            stage = u['stage']; STAGE = stage.upper()
            hx += [f' public static inline var {stage}UniformBytes={u["bytes"]};', f' public static inline var {stage}UniformName={json.dumps(u["name"])};']
            c += [f'#define HELIX_{upper}_{STAGE}_UNIFORM_SLOT {u["slot"]}', f'#define HELIX_{upper}_{STAGE}_UNIFORM_BYTES {u["bytes"]}',
                  f'_Static_assert(UB_{u["block"]} == HELIX_{upper}_{STAGE}_UNIFORM_SLOT, "Uniform block mismatch");']
        if not contract['attributes']:
            hx.append('}')
            (output / f'{type_name}.hx').write_text('\n'.join(hx) + '\n')
            contracts.append(contract)
            continue
        c += [f'static sg_vertex_layout_state helix_{program}_layout(void) {{', ' sg_vertex_layout_state layout = {0};',
              f' layout.buffers[0].stride = HELIX_{upper}_STRIDE;']
        if contract['instanceStride']:
            c += [f' layout.buffers[1].stride = HELIX_{upper}_INSTANCE_STRIDE;', ' layout.buffers[1].step_func = SG_VERTEXSTEP_PER_INSTANCE;']
        for attr in contract['attributes']:
            role = attr['role']
            for suffix, value in [('Slot', attr['slot']), ('Offset', attr['offset']), ('Components', attr['components']), ('Name', attr['name'])]:
                hx.append(f' public static inline var {role}{suffix}={json.dumps(value)};')
            c += [f' _Static_assert(ATTR_{program}_{attr["name"]} == {attr["slot"]}, "Shader attribute mismatch");',
                  f' layout.attrs[{attr["slot"]}].format = SG_VERTEXFORMAT_FLOAT{attr["components"]};',
                  f' layout.attrs[{attr["slot"]}].offset = {attr["offset"]};', f' layout.attrs[{attr["slot"]}].buffer_index = {attr["buffer"]};']
        hx.append('}'); c += [' return layout;', '}']
        (output / f'{type_name}.hx').write_text('\n'.join(hx) + '\n')
        contracts.append(contract)
    hx_shader.append('}')
    (output / 'GeneratedShader.hx').write_text('\n'.join(hx_shader) + '\n')
    (output / 'shaders.h').write_text('\n'.join(c) + '\n')
    (output / 'shader-contract.json').write_text(json.dumps(contracts, indent=2) + '\n')
    return contracts
