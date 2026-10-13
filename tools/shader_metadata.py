"""Parse sokol-shdc bare_yaml with PyYAML; generate this slice's fixed ABI.

Shader reflection describes inputs/bindings, not CPU packing. vertex.json supplies
the packed attribute order and semantic roles. Unsupported shapes fail closed.
No generated C/GLSL text is inspected to discover bindings or filenames.
"""
import json
from pathlib import Path
import re
import yaml


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


def normalize(program, schema):
    fields(program, ['name', 'vertex_func', 'fragment_func', 'attrs', 'views', 'samplers', 'texture_sampler_pairs'])
    require(program['name'] == schema['program'], 'Unexpected shader program')
    for stage in ['vertex', 'fragment']:
        function = program[stage + '_func']
        fields(function, ['path', 'is_binary', 'entry_point'])
        require(isinstance(function['path'], str) and function['is_binary'] is False and
                function['entry_point'] == 'main', 'Expected GLSL source with main entry')
    attrs = program['attrs']
    require(isinstance(attrs, list) and len(attrs) == len(schema['attributes']), 'Unexpected vertex attributes')
    by_name = {}
    slots = set()
    for attr in attrs:
        fields(attr, ['slot', 'type', 'base_type', 'glsl_name'])
        ident = name(attr['glsl_name']); index = slot(attr['slot'], 16)
        require(ident not in by_name and index not in slots, 'Duplicate attribute name or slot')
        require(attr['base_type'] == 'Float', 'Only float vertex attributes are supported')
        by_name[ident] = attr; slots.add(index)
    packed = []; offset = 0
    for spec in schema['attributes']:
        attr = by_name.get(spec['name'])
        require(attr is not None and attr['type'] == spec['type'], f'Vertex schema mismatch: {spec["role"]}')
        components = {'vec2': 2, 'vec4': 4}[spec['type']]
        packed.append(dict(spec, slot=attr['slot'], components=components, offset=offset))
        offset += components * 4
    for key in ['views', 'samplers', 'texture_sampler_pairs']:
        require(isinstance(program[key], list) and len(program[key]) == 1, f'Expected one {key} binding')
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
    return {'program': program['name'], 'stride': offset, 'attributes': packed,
            'view': texture['slot'], 'viewName': texture['name'], 'sampler': sampler['slot'],
            'samplerName': sampler['name'], 'textureUnit': pair['slot'], 'uniform': pair['glsl_name']}


def load_contract(metadata, schema_path):
    document = yaml.load(Path(metadata).read_text(), Loader=UniqueLoader)
    schema = json.loads(Path(schema_path).read_text())
    fields(schema, ['program', 'attributes']); name(schema['program'])
    require(isinstance(schema['attributes'], list) and len(schema['attributes']) == 3, 'Expected three packed attributes')
    for spec, role, kind in zip(schema['attributes'], ['position', 'uv', 'color'], ['vec2', 'vec2', 'vec4']):
        fields(spec, ['role', 'name', 'type']); name(spec['name'])
        require(spec['role'] == role and spec['type'] == kind, 'Unsupported CPU vertex packing')
    require(len({s['name'] for s in schema['attributes']}) == 3, 'Duplicate vertex schema names')
    fields(document, ['shaders'])
    require(isinstance(document['shaders'], list) and len(document['shaders']) == 2, 'Expected two shader dialects')
    programs = {}; contracts = []
    for shader in document['shaders']:
        fields(shader, ['slang', 'programs'])
        require(shader['slang'] in ['glsl410', 'glsl300es'] and shader['slang'] not in programs, 'Unexpected or duplicate dialect')
        require(isinstance(shader['programs'], list) and len(shader['programs']) == 1, 'Expected one shader program')
        program = shader['programs'][0]
        contracts.append(normalize(program, schema)); programs[shader['slang']] = program
    require(contracts[0] == contracts[1], 'Shader dialect binding layouts disagree')
    return contracts[0], programs


def generate(metadata, schema_path, output, working_dir):
    output = Path(output); working_dir = Path(working_dir)
    contract, programs = load_contract(metadata, schema_path)
    sources = {}
    for stage in ['vertex', 'fragment']:
        function = programs['glsl300es'][stage + '_func']
        fields(function, ['path', 'is_binary', 'entry_point'])
        require(function['is_binary'] is False and function['entry_point'] == 'main', 'Expected GLSL source with main entry')
        require(isinstance(function['path'], str), 'Expected a shader filename')
        path = (working_dir / function['path']).resolve()
        require(path.is_relative_to(output.resolve()), 'Shader source must be inside the generated directory')
        sources[stage] = path.read_text()  # Opaque shader contents, never scraped.
    hx = ['// Generated from structured shader reflection and vertex.json.', 'class GeneratedLayout {']
    for key in ['stride', 'view', 'sampler', 'textureUnit', 'uniform']:
        hx.append(f' public static inline var {key}={json.dumps(contract[key])};')
    c = ['/* Generated from structured shader reflection and vertex.json. */', '#pragma once',
         f'#define HELIX_SHADER_DESC {contract["program"]}_shader_desc',
         f'#define HELIX_VERTEX_STRIDE {contract["stride"]}', f'#define HELIX_VIEW_SLOT {contract["view"]}',
         f'#define HELIX_SAMPLER_SLOT {contract["sampler"]}',
         f'_Static_assert(VIEW_{contract["viewName"]} == HELIX_VIEW_SLOT, "Shader view mismatch");',
         f'_Static_assert(SMP_{contract["samplerName"]} == HELIX_SAMPLER_SLOT, "Shader sampler mismatch");',
         'static sg_vertex_layout_state helix_vertex_layout(void) {', ' sg_vertex_layout_state layout = {0};',
         ' layout.buffers[0].stride = HELIX_VERTEX_STRIDE;']
    for attr in contract['attributes']:
        role = attr['role']
        for suffix, value in [('Slot', attr['slot']), ('Offset', attr['offset']), ('Components', attr['components']), ('Name', attr['name'])]:
            hx.append(f' public static inline var {role}{suffix}={json.dumps(value)};')
        c += [f' _Static_assert(ATTR_{contract["program"]}_{attr["name"]} == {attr["slot"]}, "Shader attribute mismatch");',
              f' layout.attrs[{attr["slot"]}].format = SG_VERTEXFORMAT_FLOAT{attr["components"]};',
              f' layout.attrs[{attr["slot"]}].offset = {attr["offset"]};']
    hx.append('}'); c += [' return layout;', '}']
    (output / 'GeneratedLayout.hx').write_text('\n'.join(hx) + '\n')
    (output / 'vertex_layout.h').write_text('\n'.join(c) + '\n')
    (output / 'GeneratedShader.hx').write_text('class GeneratedShader {\n' + ''.join(
        f' public static function {stage}():String return {json.dumps(source)};\n' for stage, source in sources.items()) + '}\n')
    (output / 'shader-contract.json').write_text(json.dumps(contract, indent=2) + '\n')
    return contract
