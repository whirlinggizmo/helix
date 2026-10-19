"""Pack an app's shader (.glsl) into a HeliX shader file (.hxshader): JSON holding its program for every graphics backend HeliX has (GLSL 410
natively, GLSL ES 300 in the browser, compiled by sokol-shdc; and with --sdl-gpu SDL_GPU's SPIR-V, MSL and HLSL from the GLSL 410, by tools/gpu_shaders.py), and what the program needs bound (attributes, uniform blocks and their members,
textures). Programs load it as any asset (helix.graphics.Shaders) and the adapters build the program from it at run time.

A shader is a fragment stage `@fs fs` that includes one framework block, which decides its kind and supplies the rest:

    @include_block helix_screen   a screen effect: drawn over a whole finished frame (helix.graphics.ScreenEffect)
    @include_block helix_surface  a material's surface on a Stage3D (helix.render3d.Material.setShader): lit models, the stage's lights
                                  and their shadows, the material's base color and textures; optionally a vertex hook, `@block vertex` defining
                                  `void helix_vertex(inout vec3 position, inout vec3 normal)` (model space, before placing)

Its own parameters are uniform blocks at binding 2 and up (float, vec2, vec3, vec4 and mat4 members, and arrays of vec4 and mat4), set by name, in
either stage; its own textures follow the framework's (screen: from binding 1; surface: from binding 5), each with a sampler at the same binding.
Uniform blocks 0 and 1 are the framework's.

    python3 tools/pack_shader.py input.glsl output.hxshader"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))

ROOT = Path(__file__).resolve().parents[1]
FORMAT = 1
# The shader library's sources: packed into generated Haxe (pack_library), not loaded as assets.
LIBRARY = ROOT / 'src/helix/shaders'

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
KINDS['helix_surface'] = '''
@vs helix_surface_vs
layout(binding=0) uniform helix_surface_vs_params {
    mat4 helix_view_projection;
    vec4 helix_vs_info; // x seconds since the stage began
};
float helix_time() { return helix_vs_info.x; }
@include_block vertex
layout(location=0) in vec3 position;
layout(location=1) in vec3 normal;
layout(location=2) in vec2 uv;
layout(location=3) in vec4 tangent;
layout(location=4) in vec4 i_model0;
layout(location=5) in vec4 i_model1;
layout(location=6) in vec4 i_model2;
layout(location=7) in vec4 i_normal0;
layout(location=8) in vec4 i_normal1;
layout(location=9) in vec4 i_normal2;
layout(location=10) in vec4 i_tint;
layout(location=11) in vec4 i_lights0;
layout(location=12) in vec4 i_lights1;
out vec3 helix_v_normal;
out vec4 helix_v_tangent;
out vec2 helix_v_uv;
out vec4 helix_v_tint;
out vec3 helix_v_world;
out float helix_v_receive;
flat out vec4 helix_v_lights0;
flat out vec4 helix_v_lights1;
void main() {
    vec3 moved = position, bent = normal;
    helix_vertex(moved, bent);
    vec4 p = vec4(moved, 1.0);
    vec3 world = vec3(dot(i_model0, p), dot(i_model1, p), dot(i_model2, p));
    gl_Position = helix_view_projection * vec4(world, 1.0);
    helix_v_normal = vec3(dot(i_normal0.xyz, bent), dot(i_normal1.xyz, bent), dot(i_normal2.xyz, bent));
    helix_v_tangent = vec4(dot(i_model0.xyz, tangent.xyz), dot(i_model1.xyz, tangent.xyz), dot(i_model2.xyz, tangent.xyz), tangent.w * i_normal0.w);
    helix_v_uv = uv;
    helix_v_tint = i_tint;
    helix_v_world = world;
    helix_v_receive = i_normal1.w;
    helix_v_lights0 = i_lights0;
    helix_v_lights1 = i_lights1;
}
@end

@block helix_surface
// The stage's: its camera, ambient light, lights, environment and tone mapping (as the lit models' shader has them), the material's own
// values, and the time.
layout(binding=1) uniform helix_surface_params {
    vec4 helix_camera;        // xyz the camera's position
    vec4 helix_ambient_light; // rgb linear, times intensity
    vec4 helix_base_factor;   // the material's base color, linear rgba
    vec4 helix_pbr;           // x metallic, y roughness, z 1 lit (0 unlit)
    vec4 helix_emission;      // rgb the light it gives off, linear; w the normal map's strength
    vec4 helix_light_position[16];  // the stage's table of lights; a model's own are up to 8 of them (helix_light_index)
    vec4 helix_light_direction[16];
    vec4 helix_light_radiance[16];
    vec4 helix_light_spot[16];      // x cos(inner), y cos(outer), z its shadow slot (-1: none)
    mat4 helix_shadow_matrix[4];   // as the lit models' shader has them
    vec4 helix_shadow_params[4];
    vec4 helix_shadow_extra[4];
    vec4 helix_shadow_tint[4];
    vec4 helix_tonemap_params; // x mode (0 none, 1 Neutral, 2 ACES), y exposure's scale
    vec4 helix_environment;    // x intensity (0: none), y the cube's last mip, z/w its rotation's cosine and sine
    vec4 helix_irradiance[9];  // the environment's irradiance over pi: 9 spherical-harmonic coefficients, rgb each
    vec4 helix_fs_info;       // x seconds since the stage began
};
layout(binding=0) uniform texture2D helix_base_texture;
layout(binding=0) uniform sampler helix_base_sampler;
layout(binding=1) uniform texture2D helix_normal_texture;
layout(binding=1) uniform sampler helix_normal_sampler;
layout(binding=2) uniform texture2DArray helix_shadow_texture;
layout(binding=2) uniform sampler helix_shadow_sampler;
@image_sample_type helix_shadow_texture depth
@sampler_type helix_shadow_sampler comparison
layout(binding=3) uniform textureCube helix_environment_texture;
layout(binding=3) uniform sampler helix_environment_sampler;
layout(binding=4) uniform texture2D helix_brdf_texture;
layout(binding=4) uniform sampler helix_brdf_sampler;
in vec3 helix_v_normal;
in vec4 helix_v_tangent;
in vec2 helix_v_uv;
in vec4 helix_v_tint;
in vec3 helix_v_world;
in float helix_v_receive;
flat in vec4 helix_v_lights0;
flat in vec4 helix_v_lights1;
out vec4 helix_frag_color;
const float HELIX_PI = 3.14159265359;

vec3 helix_srgb_to_linear(vec3 c) {
    return mix(c / 12.92, pow((max(c, vec3(0.04045)) + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
float helix_time() { return helix_fs_info.x; }
vec2 helix_uv() { return helix_v_uv; }
vec3 helix_world_position() { return helix_v_world; }
vec3 helix_camera_position() { return helix_camera.xyz; }
vec3 helix_ambient() { return helix_ambient_light.rgb; }
vec3 helix_emissive() { return helix_emission.rgb; }
float helix_metallic() { return clamp(helix_pbr.x, 0.0, 1.0); }
float helix_roughness() { return clamp(helix_pbr.y, 0.03, 1.0); }
// The table entry of the model's i-th light (it's lit by up to 8 of the stage's, those reaching it most), -1 past its last.
int helix_light_index(int i) { return int(floor((i < 4 ? helix_v_lights0[i] : helix_v_lights1[i - 4]) + 0.5)); }
// How many lights light the model.
int helix_light_count() {
    int count = 0;
    for (int k = 0; k < 8; k++) {
        if (helix_light_index(k) < 0) break;
        count++;
    }
    return count;
}
// The base color: the material's, times its texture (decoded from sRGB) and the model's tint; linear.
vec4 helix_base() {
    vec4 texel = texture(sampler2D(helix_base_texture, helix_base_sampler), helix_v_uv);
    return vec4(helix_srgb_to_linear(texel.rgb), texel.a) * helix_base_factor * helix_v_tint;
}
// The surface's normal in the world: the normal map's (when the material has one) through the tangent frame, facing the viewer.
vec3 helix_normal() {
    vec3 n = normalize(helix_v_normal);
    vec3 t = helix_v_tangent.xyz - n * dot(n, helix_v_tangent.xyz);
    if (dot(t, t) > 1e-8 && helix_emission.w > 0.0) {
        t = normalize(t);
        vec3 b = cross(n, t) * helix_v_tangent.w;
        vec3 tn = texture(sampler2D(helix_normal_texture, helix_normal_sampler), helix_v_uv).xyz * 2.0 - 1.0;
        tn.xy *= helix_emission.w;
        n = normalize(mat3(t, b, n) * tn);
    }
    return gl_FrontFacing ? n : -n;
}
float helix_attenuation(float d, float range) {
    float inv_sq = 1.0 / max(d * d, 0.01);
    if (range <= 0.0) return inv_sq;
    float r = d / range;
    float w = clamp(1.0 - r * r * r * r, 0.0, 1.0);
    return w * w * inv_sq;
}
// How much of the model's light i (0 to helix_light_count() - 1) reaches world, facing n, past what casts shadows: 1 in the open, 0 in shadow (the lit models' shader's lookup, unbranched
// around its reads); 1 for a light without shadows or a model that doesn't receive them.
float helix_shadow_at(int i, vec3 world, vec3 n, vec3 to_light) {
    int s = int(helix_light_spot[helix_light_index(i)].z);
    if (s < 0 || helix_v_receive < 0.5) return 1.0;
    float slant = 1.0 - clamp(dot(n, to_light), 0.0, 1.0);
    vec4 clip = helix_shadow_matrix[s] * vec4(world + n * (helix_shadow_params[s].y * (1.0 + 2.0 * slant)), 1.0);
    vec3 ndc = clip.xyz / max(abs(clip.w), 1e-6) * sign(clip.w);
    vec2 uv = ndc.xy * 0.5 + 0.5;
    float texels = helix_shadow_params[s].z + helix_shadow_params[s].w * slant;
    vec4 extra = helix_shadow_extra[s];
    float ortho_depth = ndc.z * 0.5 + 0.5 - texels * helix_shadow_tint[s].w;
    float near_z = max(extra.y, 1e-4), far_z = max(extra.z, near_z + 1e-3);
    float z = 2.0 * near_z * far_z / max(far_z + near_z - ndc.z * (far_z - near_z), 1e-6);
    float z_slack = max(z - texels * helix_shadow_params[s].y * (z / far_z), near_z);
    float spot_depth = (far_z + near_z - 2.0 * near_z * far_z / z_slack) / (far_z - near_z) * 0.5 + 0.5;
    float depth = mix(ortho_depth, spot_depth, step(0.5, extra.w));
    vec2 to_edge = 1.0 - abs(ndc.xy);
    float edge = clamp(min(to_edge.x, to_edge.y) / 0.1, 0.0, 1.0) * step(0.0, min(to_edge.x, to_edge.y)) * step(depth, 1.0) * step(0.0, clip.w);
    float texel = helix_shadow_params[s].x, lit = 0.0;
    vec2 at = clamp(uv, vec2(texel), vec2(1.0 - texel));
    for (int y = -1; y <= 1; y++)
        for (int x = -1; x <= 1; x++)
            lit += texture(sampler2DArrayShadow(helix_shadow_texture, helix_shadow_sampler), vec4(at + vec2(float(x), float(y)) * texel, float(s), clamp(depth, 0.0, 1.0)));
    return mix(1.0, lit / 9.0, edge * extra.x);
}
// The model's light i (0 to helix_light_count() - 1) at world, facing n: the radiance reaching it (color times intensity, its falloff, cone and shadow applied), to_light, the direction
// toward it, and lit, how much of it its shadow lets through.
vec3 helix_light_lit(int i, vec3 world, vec3 n, out vec3 to_light, out float lit) {
    int t = helix_light_index(i);
    float falloff = 1.0;
    vec3 travel;
    if (helix_light_direction[t].w < 0.5) {
        travel = normalize(helix_light_direction[t].xyz);
    } else {
        vec3 to_frag = world - helix_light_position[t].xyz;
        float d = length(to_frag);
        travel = d > 1e-6 ? to_frag / d : vec3(0.0, -1.0, 0.0);
        falloff = helix_attenuation(d, helix_light_position[t].w);
        if (helix_light_direction[t].w > 1.5) {
            float inner = helix_light_spot[t].x, outer = helix_light_spot[t].y, c = dot(travel, normalize(helix_light_direction[t].xyz));
            falloff *= inner - outer <= 1e-6 ? (c >= outer ? 1.0 : 0.0) : smoothstep(outer, inner, c);
        }
    }
    to_light = -travel;
    lit = helix_shadow_at(i, world, n, to_light);
    return helix_light_radiance[t].rgb * falloff * lit;
}
// The model's light i (0 to helix_light_count() - 1) at world, facing n: the radiance reaching it (color times intensity, its falloff, cone and shadow applied) and to_light, the
// direction toward it.
vec3 helix_light(int i, vec3 world, vec3 n, out vec3 to_light) {
    float lit;
    return helix_light_lit(i, world, n, to_light, lit);
}
// Whether the stage has an environment to light by.
bool helix_has_environment() { return helix_environment.x > 0.0; }
// A world direction in the environment's frame.
vec3 helix_environment_direction(vec3 d) {
    return vec3(helix_environment.z * d.x - helix_environment.w * d.z, d.y, helix_environment.w * d.x + helix_environment.z * d.z);
}
// The environment's light on a surface facing unit n, over pi (times a diffuse color: its diffuse light), times its intensity; 0 without one.
vec3 helix_environment_irradiance(vec3 n) {
    vec3 d = helix_environment_direction(n);
    vec3 e = helix_irradiance[0].xyz * 0.282095 + helix_irradiance[1].xyz * (0.488603 * d.y) + helix_irradiance[2].xyz * (0.488603 * d.z)
        + helix_irradiance[3].xyz * (0.488603 * d.x) + helix_irradiance[4].xyz * (1.092548 * d.x * d.y) + helix_irradiance[5].xyz * (1.092548 * d.y * d.z)
        + helix_irradiance[6].xyz * (0.315392 * (3.0 * d.z * d.z - 1.0)) + helix_irradiance[7].xyz * (1.092548 * d.x * d.z)
        + helix_irradiance[8].xyz * (0.546274 * (d.x * d.x - d.y * d.y));
    return max(e, vec3(0.0)) * helix_environment.x;
}
// The environment as a surface of roughness (0..1) reflects it in world direction r, times its intensity; 0 without one.
vec3 helix_environment_reflection(vec3 r, float roughness) {
    return textureLod(samplerCube(helix_environment_texture, helix_environment_sampler), helix_environment_direction(r), roughness * helix_environment.y).rgb
        * helix_environment.x;
}
// The split-sum BRDF table at n.v and roughness: specular reflectance is f0 * x + y.
vec2 helix_environment_brdf(float n_dot_v, float roughness) {
    return texture(sampler2D(helix_brdf_texture, helix_brdf_sampler), vec2(n_dot_v, roughness)).rg;
}
// The stage's own shading of base with normal n (glTF metallic-roughness under its lights, environment and ambient light, plus emission):
// for a shader that only changes the inputs.
vec3 helix_shade(vec3 n, vec4 base) {
    float metallic = helix_metallic(), alpha = helix_roughness() * helix_roughness(), alpha_sq = alpha * alpha;
    vec3 f0 = mix(vec3(0.04), base.rgb, metallic), c_diff = base.rgb * (1.0 - metallic);
    vec3 v = normalize(helix_camera.xyz - helix_v_world);
    float n_dot_v = clamp(abs(dot(n, v)), 1e-4, 1.0);
    vec3 color = helix_ambient_light.rgb * (c_diff + f0);
    for (int i = 0; i < 4; i++) {
        if (i >= helix_light_count()) break;
        vec3 l;
        float lit;
        vec3 radiance = helix_light_lit(i, helix_v_world, n, l, lit);
        // What a shadow keeps: its tint, deepest where it's darkest.
        int s = int(helix_light_spot[i].z);
        if (s >= 0) color += helix_shadow_tint[s].rgb * (1.0 - lit) * c_diff;
        float n_dot_l = dot(n, l);
        if (n_dot_l <= 0.0) continue;
        vec3 h = normalize(l + v);
        float n_dot_h = clamp(dot(n, h), 0.0, 1.0), v_dot_h = clamp(dot(v, h), 0.0, 1.0);
        vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - v_dot_h, 5.0);
        float dd = n_dot_h * n_dot_h * (alpha_sq - 1.0) + 1.0, distribution = alpha_sq / (HELIX_PI * dd * dd);
        float gv = n_dot_l * sqrt(n_dot_v * n_dot_v * (1.0 - alpha_sq) + alpha_sq), gl = n_dot_v * sqrt(n_dot_l * n_dot_l * (1.0 - alpha_sq) + alpha_sq);
        color += radiance * n_dot_l * ((1.0 - fresnel) * c_diff / HELIX_PI + fresnel * distribution * 0.5 / max(gv + gl, 1e-6));
    }
    if (helix_has_environment()) {
        vec2 ab = helix_environment_brdf(n_dot_v, helix_roughness());
        color += helix_environment_irradiance(n) * c_diff + helix_environment_reflection(reflect(-v, n), helix_roughness()) * (f0 * ab.x + ab.y);
    }
    return color + helix_emission.rgb;
}
// Khronos PBR Neutral.
vec3 helix_tonemap_neutral(vec3 color) {
    const float start = 0.8 - 0.04, desaturation = 0.15;
    float x = min(color.r, min(color.g, color.b));
    color -= x < 0.08 ? x - 6.25 * x * x : 0.04;
    float peak = max(color.r, max(color.g, color.b));
    if (peak < start) return color;
    const float d = 1.0 - start;
    float new_peak = 1.0 - d * d / (peak + d - start);
    color *= new_peak / peak;
    return mix(color, vec3(new_peak), 1.0 - 1.0 / (desaturation * (peak - new_peak) + 1.0));
}
// The stage's exposure and tone mapping (none, Neutral or ACES) of linear color: into 0..1.
vec3 helix_tonemap(vec3 color) {
    color *= helix_tonemap_params.y;
    int mode = int(helix_tonemap_params.x + 0.5);
    if (mode == 1) return helix_tonemap_neutral(color);
    if (mode == 2) {
        color *= 0.6;
        return clamp((color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14), 0.0, 1.0);
    }
    return color;
}
// Writes linear color (tone mapped, then encoded as the framebuffer's sRGB) and alpha.
void helix_output(vec3 color, float alpha) {
    vec3 c = clamp(helix_tonemap(color), vec3(0.0), vec3(1.0));
    helix_frag_color = vec4(mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0031308)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c)), alpha);
}
@end
'''
VERTEX = {'helix_screen': 'helix_screen_vs', 'helix_surface': 'helix_surface_vs'}
ATTRIBUTES = {'helix_screen': [], 'helix_surface': ['position', 'normal', 'uv', 'tangent', 'i_model0', 'i_model1', 'i_model2', 'i_normal0', 'i_normal1',
                                                    'i_normal2', 'i_tint']}
# The first texture binding an app's own may use.
FIRST_TEXTURE = {'helix_screen': 1, 'helix_surface': 5}
NO_VERTEX_HOOK = '''
@block vertex
void helix_vertex(inout vec3 position, inout vec3 normal) {}
@end
'''

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


def packed(shdc, source_path, sdl_gpu=False):
    """source_path packed: the .hxshader's content as a dict, with SDL_GPU's dialects (tools/gpu_shaders.py) only when sdl_gpu, so other
    builds need neither glslang nor SPIRV-Cross."""
    source = Path(source_path).read_text(encoding='utf-8')
    kinds = [k for k in KINDS if re.search(r'@include_block\s+' + k + r'\b', source)]
    if len(kinds) != 1:
        fail(f'{source_path}: include exactly one framework block ({", ".join(KINDS)})')
    if not re.search(r'@fs\s+fs\b', source):
        fail(f'{source_path}: the fragment stage must be "@fs fs"')
    kind = kinds[0]
    program = 'shader'
    # The vertex hook block comes first, as the framework's vertex stage includes it.
    found = re.search(r'@block\s+vertex\b.*?@end', source, re.S)
    hook, rest = (found.group(0), source[:found.start()] + source[found.end():]) if found else (NO_VERTEX_HOOK if kind == 'helix_surface' else '', source)
    if found and kind != 'helix_surface':
        fail(f'{source_path}: only a surface shader has a vertex hook')
    full = hook + '\n' + KINDS[kind] + '\n' + rest + f'\n@program {program} {VERTEX[kind]} fs\n'
    with tempfile.TemporaryDirectory() as scratch:
        scratch = Path(scratch)
        (scratch / 'shader.glsl').write_text(full, encoding='utf-8')
        for args in (['-o', scratch / 'shader.h'], ['-o', scratch / 'shader', '-f', 'bare_yaml']):
            done = subprocess.run([shdc, '-i', scratch / 'shader.glsl', *args, '-l', 'glsl410:glsl300es', '--no-log-cmdline'],
                                  capture_output=True, text=True, encoding='utf-8')
            if done.returncode:
                fail(f'{source_path}: sokol-shdc failed\n{done.stdout}{done.stderr}'.replace(str(scratch / 'shader.glsl'), str(source_path)))
        reflection = yaml.safe_load((scratch / 'shader_reflection.yaml').read_text(encoding='utf-8'))
        dialects, first = {}, None
        for entry in reflection['shaders']:
            p = entry['programs'][0]
            dialects[entry['slang']] = {'vertex': Path(p['vertex_func']['path']).read_text(encoding='utf-8'),
                                        'fragment': Path(p['fragment_func']['path']).read_text(encoding='utf-8')}
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
        if not pair['view_name'].startswith('helix_') and pair['view_slot'] < FIRST_TEXTURE[kind]:
            fail(f'{source_path}: texture {pair["view_name"]} needs binding {FIRST_TEXTURE[kind]} or more; the lower ones are the framework\'s')
        textures.append({'slot': pair['view_slot'], 'stage': pair['stage'], 'name': pair['view_name'], 'glslName': pair['glsl_name'],
                         'shadow': views.get(pair['view_slot'], {}).get('sample_type') == 'depth',
                         'cube': views.get(pair['view_slot'], {}).get('type') == 'cube',
                         'data': views.get(pair['view_slot'], {}).get('sample_type') == 'unfilterable_float'})
    if set(views) != {t['slot'] for t in textures}:
        fail(f'{source_path}: every texture needs a sampler')
    shader = {'helixShader': FORMAT, 'kind': kind.removeprefix('helix_'), 'attributes': ATTRIBUTES[kind], 'glsl410': dialects['glsl410'],
              'glsl300es': dialects['glsl300es'], 'uniformBlocks': sorted(blocks, key=lambda b: b['slot']),
              'textures': sorted(textures, key=lambda t: t['slot'])}
    if sdl_gpu:
        import gpu_shaders
        shader['sdlGpu'] = gpu_shaders.translate(dialects['glsl410']['vertex'], dialects['glsl410']['fragment'], blocks, textures)
    return shader


def pack(shdc, source_path, output_path, sdl_gpu=False):
    """Packs source_path into output_path (a .hxshader), with SDL_GPU's dialects only when sdl_gpu."""
    shader = packed(shdc, source_path, sdl_gpu)
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    Path(output_path).write_text(json.dumps(shader, indent=1) + '\n', encoding='utf-8')


def class_name(stem):
    """The Haxe class name of a library shader's file stem: its words capitalized, "color_lut" ColorLut."""
    return ''.join(word[:1].upper() + word[1:] for word in re.split(r'[_-]', stem) if word)


def haxe_string(text):
    """text as a Haxe string literal: JSON's escapes (backslash, quote, newline, \\u and four hex digits) are Haxe's too."""
    return json.dumps(text)


def pack_library(out, gpu_out=None, sources=LIBRARY, shdc=None):
    """The shader library (src/helix/shaders/*.glsl) packed into generated Haxe in out, so a class in helix.shaders gets its shader with no
    load: <Name>Packed.hx, whose text() is the .hxshader's text, and PackedShaders.hx naming them all (for the dev loop's hot reload); with
    gpu_out (SDL_GPU builds), SDL_GPU's dialects too, as <Name>PackedSdlGpu.hx there, which text() returns in builds defining
    helix_sdl3_gpu. A shader is packed again only when its source or this tool is newer than its output; generated files whose source is gone
    are removed. shdc is sokol-shdc's path, found when first needed. Returns the stems packed."""
    out, sources = Path(out), Path(sources)
    out.mkdir(parents=True, exist_ok=True)
    stems = sorted(p.stem for p in sources.glob('*.glsl'))
    tool = Path(__file__).stat().st_mtime
    made = []
    outputs = [(out, 'Packed', False)] + ([(Path(gpu_out), 'PackedSdlGpu', True)] if gpu_out else [])
    for folder, suffix, sdl_gpu in outputs:
        folder.mkdir(parents=True, exist_ok=True)
        wanted = {class_name(stem) + suffix for stem in stems}
        for stale in folder.glob('*' + suffix + '.hx'):
            if stale.stem not in wanted:
                stale.unlink()
        for stem in stems:
            source, name = sources / f'{stem}.glsl', class_name(stem)
            target = folder / f'{name}{suffix}.hx'
            if target.is_file() and target.stat().st_mtime >= max(source.stat().st_mtime, tool, gpu_tool_stamp() if sdl_gpu else 0):
                continue
            shdc = shdc or shdc_path()
            text = json.dumps(packed(shdc, source, sdl_gpu), separators=(',', ':'))
            origin = source.relative_to(ROOT).as_posix() if source.is_relative_to(ROOT) else source.name
            if sdl_gpu:
                lines = [f'// Generated by tools/pack_shader.py from {origin}: its .hxshader with SDL_GPU\'s dialects, for builds defining helix_sdl3_gpu.',
                         f'class {name}{suffix} {{', ' /** The .hxshader\'s text, with SDL_GPU\'s dialects. */', ' public static function text():String',
                         f'  return {haxe_string(text)};', '}']
            else:
                lines = [f'// Generated by tools/pack_shader.py from {origin}: its .hxshader, packed into the program.', f'class {name}{suffix} {{',
                         ' /** The .hxshader\'s text (helix.graphics.Shader.fromText reads it): with SDL_GPU\'s dialects in builds defining helix_sdl3_gpu. */',
                         ' public static function text():String', '  #if helix_sdl3_gpu', f'  return {name}PackedSdlGpu.text();', '  #else',
                         f'  return {haxe_string(text)};', '  #end', '}']
            target.write_text('\n'.join(lines) + '\n', encoding='utf-8')
            if stem not in made:
                made.append(stem)
    registry = out / 'PackedShaders.hx'
    content = '\n'.join(['// Generated by tools/pack_shader.py: the shader library packed into the program (src/helix/shaders), by file stem.',
                         'class PackedShaders {', ' /** Each library shader\'s .hxshader text, by its file\'s stem: what a hot reload builds them again from. */',
                         ' public static function texts():Map<String, Void->String>',
                         '  return [' + ', '.join(f'"{stem}" => () -> {class_name(stem)}Packed.text()' for stem in stems) + '];', '}']) + '\n'
    if not stems:
        content = content.replace('  return [];', '  return new Map();')
    if not registry.is_file() or registry.read_text(encoding='utf-8') != content:
        registry.write_text(content, encoding='utf-8')
    return made


def gpu_tool_stamp():
    """When SDL_GPU's translators last changed (tools/gpu_shaders.py)."""
    import gpu_shaders
    return gpu_shaders.tool_stamp()


def shdc_path():
    """The pinned sokol-shdc (tools/shdc.py)."""
    sys.path.insert(0, str(ROOT / 'tools'))
    import shdc
    return shdc.path()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('input')
    parser.add_argument('output')
    parser.add_argument('--sdl-gpu', action='store_true', help="with SDL_GPU's dialects")
    a = parser.parse_args()
    pack(shdc_path(), a.input, a.output, a.sdl_gpu)
