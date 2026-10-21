
// The stage's: its camera, ambient light, lights, environment and tone mapping (as the lit models' shader has them), the material's own
// values (its hit flash and rim light among them, which helix_output applies), and the time.
layout(binding=1) uniform helix_surface_params {
    vec4 helix_camera;        // xyz the camera's position
    vec4 helix_ambient_light; // rgb linear, times intensity
    vec4 helix_base_factor;   // the material's base color, linear rgba
    vec4 helix_pbr;           // x metallic, y roughness, z 1 lit (0 unlit)
    vec4 helix_emission;      // rgb the light it gives off, linear; w the normal map's strength
    vec4 helix_flash;         // the material's hit flash: rgb linear, a how much (0 none)
    vec4 helix_rim;           // the material's rim light: rgb linear times its strength (black: none), w its power
    vec4 helix_light_position[16];  // the stage's table of lights; a model's own are up to 8 of them (helix_light_index)
    vec4 helix_light_direction[16];
    vec4 helix_light_radiance[16];
    vec4 helix_light_spot[16];      // x cos(inner), y cos(outer), z its shadow slot (-1: none)
    mat4 helix_shadow_matrix[4];   // as the lit models' shader has them
    vec4 helix_shadow_params[4];
    vec4 helix_shadow_extra[4];
    vec4 helix_shadow_tint[4];
    vec4 helix_tonemap_params; // x mode (0 none, 1 Neutral, 2 ACES), y exposure's scale, z 1 in an HDR scene
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
layout(binding=3) uniform textureCube helix_environment_texture;
layout(binding=3) uniform sampler helix_environment_sampler;
layout(binding=4) uniform texture2D helix_brdf_texture;
layout(binding=4) uniform sampler helix_brdf_sampler;
in vec3 helix_v_normal;
in vec3 helix_v_model_position;
in vec3 helix_v_model_normal;
in vec4 helix_v_tangent;
in vec2 helix_v_uv;
in vec4 helix_v_tint;
in vec3 helix_v_world;
in float helix_v_receive;
flat in vec4 helix_v_lights0;
flat in vec4 helix_v_lights1;
const float HELIX_PI = 3.14159265359;

vec3 helix_srgb_to_linear(vec3 c) {
    return mix(c / 12.92, pow((max(c, vec3(0.04045)) + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
float helix_time() { return helix_fs_info.x; }
vec2 helix_uv() { return helix_v_uv; }
vec3 helix_world_position() { return helix_v_world; }
// Where this is on the model at rest, in its own space (its vertices as given, before skinning and the vertex hook: a skinned model's bind
// pose), and the surface's unit normal there: the same for a static, instanced or skinned model, and in its shadow caster, so a pattern
// laid by them stays on the surface as the model moves, animates or waves, and its shadow follows it.
vec3 helix_model_position() { return helix_v_model_position; }
vec3 helix_model_normal() { return normalize(helix_v_model_normal); }
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
// The direction toward the camera from here, in the world.
vec3 helix_view_direction() { return normalize(helix_camera.xyz - helix_v_world); }
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
    vec3 v = helix_view_direction();
    float n_dot_v = clamp(abs(dot(n, v)), 1e-4, 1.0);
    vec3 color = helix_ambient_light.rgb * (c_diff + f0);
    for (int i = 0; i < 4; i++) {
        if (i >= helix_light_count()) break;
        vec3 l;
        float lit;
        vec3 radiance = helix_light_lit(i, helix_v_world, n, l, lit);
        // What a shadow keeps: its tint, deepest where it's darkest.
        int s = int(helix_light_spot[helix_light_index(i)].z);
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
// The stage's tone mapping (none, Neutral or ACES) of light after the exposure: into 0..1.
vec3 helix_tonemap_curve(vec3 color) {
    int mode = int(helix_tonemap_params.x + 0.5);
    if (mode == 1) return helix_tonemap_neutral(color);
    if (mode == 2) {
        color *= 0.6;
        return clamp((color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14), 0.0, 1.0);
    }
    return color;
}
// The stage's exposure and tone mapping (none, Neutral or ACES) of linear color: into 0..1.
vec3 helix_tonemap(vec3 color) { return helix_tonemap_curve(color * helix_tonemap_params.y); }
// The material's rim light here (helix.shaders.Rim): its color, brightest where the surface turns away from the viewer; 0 without one.
vec3 helix_rim_light() {
    return helix_rim.rgb * pow(1.0 - clamp(abs(dot(normalize(helix_v_normal), helix_view_direction())), 0.0, 1.0), helix_rim.w);
}
