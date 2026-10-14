/* What the lit models' programs share, included by lit3d.glsl (static models) and skinned3d.glsl (skinned ones): their vertex inputs and
 * placing, their fragment block's members and their whole fragment stage.
 *
 * Lit models (render3d's Stage3D): glTF metallic-roughness materials lit by up to 4 lights and an environment, tone mapped and written as
 * sRGB. The BRDF follows glTF 2.0's appendix B: Lambert diffuse, GGX / Smith height-correlated specular, Schlick Fresnel. Each instance's
 * placement (the model matrix's rows), its normals' matrix (the inverse transpose's rows) and its tint come from the instance buffer, so
 * placements alike in everything else are one draw.
 *
 * Color space: the framebuffer holds sRGB values. The base color texture is decoded from sRGB; the normal map is linear (tangent space,
 * green up, as glTF's); factors, tints, emissive and light radiance are linear; lighting happens in linear space. i_normal0.w is the
 * tangents' handedness: -1 where the placement mirrors them; i_normal1.w is 1 where the model receives shadows; i_normal2.w a skinned model's
 * first joint in the joint texture.
 *
 * Shadows: a casting light has a slot (light_spot[i].z; -1 for none), a layer of the shadow map (a depth array, read through a comparison
 * sampler). Its map is looked up a texel or so along the normal (more where the light grazes the surface) with a little depth slack in texels
 * on top, filtered over 3x3 texels by the GPU, and fades out over the map's last tenth. No branch guards these reads (Adreno's compiler can't
 * bound one): what's outside the map is a weight.
 *
 * Environment: split-sum image-based light. Diffuse from its irradiance (9 spherical-harmonic coefficients, over pi), specular from its
 * prefiltered cube (a mip a roughness step) scaled by the split-sum BRDF table (A, B by n.v and roughness: F0 * A + B), both turned about +y
 * by its rotation and times its intensity (0: no environment, the cube and table not read).
 *
 * Tone mapping: exposure scales the light, then 0 none (clamped), 1 Khronos PBR Neutral or 2 ACES (Narkowicz's fit) brings it into 0..1.
 *
 * lit3d_vs_params: view_projection
 * lit3d_fs_params:
 *   camera_position    xyz
 *   ambient            rgb, linear, times intensity
 *   base_color         linear rgba, the material's
 *   pbr                x metallic, y roughness, z 1 = lit (0 = unlit), w the number of lights (0..4)
 *   emissive           rgb linear light the surface gives off, w the normal map's strength
 *   light_position[i]  xyz position, w range (0: unlimited)
 *   light_direction[i] xyz the direction the light travels, w type (0 directional, 1 point, 2 spot)
 *   light_radiance[i]  rgb color times intensity, linear
 *   light_spot[i]      x cos(inner cone), y cos(outer cone): a spot's full light inside the inner, none past the outer; z its shadow slot
 *   shadow_matrix[s]   world -> the slot's light's clip space (GL's -1..1 depth)
 *   shadow_params[s]   x a texel in uv (1 / the map's size), y a texel in world units, z/w bias constant, slope (texels)
 *   shadow_extra[s]    x strength (how much light a shadow takes); a perspective (spot) map: y/z its near and far, w 1
 *   shadow_tint[s]     rgb what a shadow leaves behind (linear), w bias texels -> depth units (an orthographic map's)
 *   tonemap            x mode (0 none, 1 Neutral, 2 ACES), y exposure's scale (2 to the EV)
 *   environment        x intensity (0: none), y the prefiltered cube's last mip, z/w the cosine and sine of its rotation about +y
 *   irradiance[9]      xyz each coefficient's rgb */

@block lit3d_vertex
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
out vec3 v_normal;
out vec4 v_tangent;
out vec2 v_uv;
out vec4 v_tint;
out vec3 v_world;
out float v_receive;
// Places a vertex (its position, normal and tangent in the model's space) by its instance's record.
void lit3d_place(vec3 placed, vec3 bent, vec3 turned) {
    vec4 p = vec4(placed, 1.0);
    vec3 world = vec3(dot(i_model0, p), dot(i_model1, p), dot(i_model2, p));
    gl_Position = view_projection * vec4(world, 1.0);
    v_normal = vec3(dot(i_normal0.xyz, bent), dot(i_normal1.xyz, bent), dot(i_normal2.xyz, bent));
    v_tangent = vec4(dot(i_model0.xyz, turned), dot(i_model1.xyz, turned), dot(i_model2.xyz, turned), tangent.w * i_normal0.w);
    v_uv = uv;
    v_tint = i_tint;
    v_world = world;
    v_receive = i_normal1.w;
}
@end

@block lit3d_fs_members
    vec4 camera_position;
    vec4 ambient;
    vec4 base_color;
    vec4 pbr;
    vec4 emissive;
    vec4 light_position[4];
    vec4 light_direction[4];
    vec4 light_radiance[4];
    vec4 light_spot[4];
    mat4 shadow_matrix[4];
    vec4 shadow_params[4];
    vec4 shadow_extra[4];
    vec4 shadow_tint[4];
    vec4 tonemap;
    vec4 environment;
    vec4 irradiance[9];
@end

@block lit3d_fragment
const float PI = 3.14159265359;
layout(binding=0) uniform texture2D lit3d_base_texture;
layout(binding=0) uniform sampler lit3d_base_sampler;
layout(binding=1) uniform texture2D lit3d_normal_texture;
layout(binding=1) uniform sampler lit3d_normal_sampler;
layout(binding=2) uniform texture2DArray lit3d_shadow_texture;
layout(binding=2) uniform sampler lit3d_shadow_sampler;
@image_sample_type lit3d_shadow_texture depth
@sampler_type lit3d_shadow_sampler comparison
layout(binding=3) uniform textureCube lit3d_environment_texture;
layout(binding=3) uniform sampler lit3d_environment_sampler;
layout(binding=4) uniform texture2D lit3d_brdf_texture;
layout(binding=4) uniform sampler lit3d_brdf_sampler;
in vec3 v_normal;
in vec4 v_tangent;
in vec2 v_uv;
in vec4 v_tint;
in vec3 v_world;
in float v_receive;
out vec4 frag_color;

vec3 srgb_to_linear(vec3 c) {
    return mix(c / 12.92, pow((max(c, vec3(0.04045)) + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 linear_to_srgb(vec3 c) {
    c = clamp(c, vec3(0.0), vec3(1.0));
    return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0031308)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

/* Khronos PBR Neutral (https://github.com/KhronosGroup/ToneMapping) */
vec3 tonemap_neutral(vec3 color) {
    const float start_compression = 0.8 - 0.04;
    const float desaturation = 0.15;
    float x = min(color.r, min(color.g, color.b));
    float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
    color -= offset;
    float peak = max(color.r, max(color.g, color.b));
    if (peak < start_compression) {
        return color;
    }
    const float d = 1.0 - start_compression;
    float new_peak = 1.0 - d * d / (peak + d - start_compression);
    color *= new_peak / peak;
    float g = 1.0 - 1.0 / (desaturation * (peak - new_peak) + 1.0);
    return mix(color, vec3(new_peak), g);
}

/* ACES filmic curve fit (Narkowicz 2015) */
vec3 tonemap_aces(vec3 color) {
    color *= 0.6;
    return clamp((color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14), 0.0, 1.0);
}

/* Linear light to the framebuffer's sRGB: exposure, then the tone mapping. */
vec3 to_display(vec3 color) {
    color *= tonemap.y;
    int mode = int(tonemap.x + 0.5);
    if (mode == 1) {
        color = tonemap_neutral(color);
    } else if (mode == 2) {
        color = tonemap_aces(color);
    }
    return linear_to_srgb(color);
}

/* A world direction in the environment's frame: turned by -rotation about +y. */
vec3 environment_direction(vec3 d) {
    return vec3(environment.z * d.x - environment.w * d.z, d.y, environment.w * d.x + environment.z * d.z);
}

/* The environment's irradiance over pi toward unit n (in its frame). */
vec3 environment_irradiance(vec3 n) {
    return irradiance[0].xyz * 0.282095
         + irradiance[1].xyz * (0.488603 * n.y)
         + irradiance[2].xyz * (0.488603 * n.z)
         + irradiance[3].xyz * (0.488603 * n.x)
         + irradiance[4].xyz * (1.092548 * n.x * n.y)
         + irradiance[5].xyz * (1.092548 * n.y * n.z)
         + irradiance[6].xyz * (0.315392 * (3.0 * n.z * n.z - 1.0))
         + irradiance[7].xyz * (1.092548 * n.x * n.z)
         + irradiance[8].xyz * (0.546274 * (n.x * n.x - n.y * n.y));
}

float spot_factor(float cos_angle, float cos_inner, float cos_outer) {
    if (cos_inner - cos_outer <= 1e-6) {
        return cos_angle >= cos_outer ? 1.0 : 0.0;
    }
    return smoothstep(cos_outer, cos_inner, cos_angle);
}

float attenuation(float d, float range) {
    float inv_sq = 1.0 / max(d * d, 0.01);
    if (range <= 0.0) {
        return inv_sq;
    }
    float r = d / range;
    float w = clamp(1.0 - r * r * r * r, 0.0, 1.0);
    return w * w * inv_sq;
}

/* How much of shadow slot s's light reaches world (normal n, n_dot_l toward the light): 1 in the open, 0 in shadow, between across an edge. */
float shadow_factor(int s, vec3 world, vec3 n, float n_dot_l) {
    // Looked up a little along the normal rather than pushed far back in depth: no striping, and the shadow stays at its caster's foot.
    float slant = 1.0 - clamp(n_dot_l, 0.0, 1.0);
    vec4 clip = shadow_matrix[s] * vec4(world + n * (shadow_params[s].y * (1.0 + 2.0 * slant)), 1.0);
    vec3 ndc = clip.xyz / max(abs(clip.w), 1e-6) * sign(clip.w);
    vec2 uv = ndc.xy * 0.5 + 0.5;
    /* Slack in texels. An orthographic map's depth is linear, converted once; a perspective map's isn't, so there it's taken in world units at
     * this fragment's distance (a texel covers texel_world * z / far) and converted back. Both are worked out and one picked arithmetically; the
     * clamps keep an orthographic slot's planes (0) finite, as mix() carries a NaN through even at weight 0. */
    float texels = shadow_params[s].z + shadow_params[s].w * slant;
    vec4 extra = shadow_extra[s];
    float ortho_depth = ndc.z * 0.5 + 0.5 - texels * shadow_tint[s].w;
    float near_z = max(extra.y, 1e-4);
    float far_z = max(extra.z, near_z + 1e-3);
    float z = 2.0 * near_z * far_z / max(far_z + near_z - ndc.z * (far_z - near_z), 1e-6);
    float z_slack = max(z - texels * shadow_params[s].y * (z / far_z), near_z);
    float spot_depth = (far_z + near_z - 2.0 * near_z * far_z / z_slack) / (far_z - near_z) * 0.5 + 0.5;
    float depth = mix(ortho_depth, spot_depth, step(0.5, extra.w));
    // Past the map's sides, its far end or behind the light, lit; fading over the last tenth, so a shadow running off the map dissolves.
    vec2 to_edge = 1.0 - abs(ndc.xy);
    float inside = step(0.0, min(to_edge.x, to_edge.y)) * step(depth, 1.0) * step(0.0, clip.w);
    float edge = clamp(min(to_edge.x, to_edge.y) / 0.1, 0.0, 1.0) * inside;
    float texel = shadow_params[s].x;
    vec2 at = clamp(uv, vec2(texel), vec2(1.0 - texel));
    float lit = 0.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            lit += texture(sampler2DArrayShadow(lit3d_shadow_texture, lit3d_shadow_sampler),
                           vec4(at + vec2(float(x), float(y)) * texel, float(s), clamp(depth, 0.0, 1.0)));
        }
    }
    return mix(1.0, lit / 9.0, edge * extra.x);
}

void main() {
    vec4 texel = texture(sampler2D(lit3d_base_texture, lit3d_base_sampler), v_uv);
    vec4 base = vec4(srgb_to_linear(texel.rgb), texel.a) * base_color * v_tint;
    if (pbr.z < 0.5) {
        frag_color = vec4(to_display(base.rgb + emissive.rgb), base.a);
        return;
    }
    // The shading frame: the normal map's direction through the tangent, the bitangent and the normal.
    vec3 n = normalize(v_normal);
    vec3 t = v_tangent.xyz - n * dot(n, v_tangent.xyz);
    if (dot(t, t) > 1e-8 && emissive.w > 0.0) {
        t = normalize(t);
        vec3 b = cross(n, t) * v_tangent.w;
        vec3 tn = texture(sampler2D(lit3d_normal_texture, lit3d_normal_sampler), v_uv).xyz * 2.0 - 1.0;
        tn.xy *= emissive.w;
        n = normalize(mat3(t, b, n) * tn);
    }
    n *= gl_FrontFacing ? 1.0 : -1.0;
    float metallic = clamp(pbr.x, 0.0, 1.0);
    float roughness = clamp(pbr.y, 0.03, 1.0);
    float alpha = roughness * roughness;
    float alpha_sq = alpha * alpha;
    vec3 f0 = mix(vec3(0.04), base.rgb, metallic);
    vec3 c_diff = base.rgb * (1.0 - metallic);
    vec3 v = normalize(camera_position.xyz - v_world);
    float n_dot_v = clamp(abs(dot(n, v)), 1e-4, 1.0);
    vec3 color = ambient.rgb * (c_diff + f0);
    int count = int(pbr.w + 0.5);
    for (int i = 0; i < 4; i++) {
        if (i >= count) {
            break;
        }
        vec3 light_dir;
        float falloff = 1.0;
        if (light_direction[i].w < 0.5) {
            light_dir = normalize(light_direction[i].xyz);
        } else {
            vec3 to_frag = v_world - light_position[i].xyz;
            float d = length(to_frag);
            light_dir = d > 1e-6 ? to_frag / d : vec3(0.0, -1.0, 0.0);
            falloff = attenuation(d, light_position[i].w);
            if (light_direction[i].w > 1.5) {
                falloff *= spot_factor(dot(light_dir, normalize(light_direction[i].xyz)), light_spot[i].x, light_spot[i].y);
            }
        }
        vec3 l = -light_dir;
        float n_dot_l = dot(n, l);
        if (n_dot_l <= 0.0 || falloff <= 0.0) {
            continue;
        }
        vec3 h = normalize(l + v);
        float n_dot_h = clamp(dot(n, h), 0.0, 1.0);
        float v_dot_h = clamp(dot(v, h), 0.0, 1.0);
        vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - v_dot_h, 5.0);
        float dd = n_dot_h * n_dot_h * (alpha_sq - 1.0) + 1.0;
        float distribution = alpha_sq / (PI * dd * dd);
        float gv = n_dot_l * sqrt(n_dot_v * n_dot_v * (1.0 - alpha_sq) + alpha_sq);
        float gl = n_dot_v * sqrt(n_dot_l * n_dot_l * (1.0 - alpha_sq) + alpha_sq);
        float visibility = 0.5 / max(gv + gl, 1e-6);
        vec3 diffuse = (1.0 - fresnel) * c_diff / PI;
        vec3 specular = fresnel * distribution * visibility;
        // A light with a map is shadowed by it where the model receives; the tint is what a shadow keeps, deepest where it's darkest.
        int s = int(light_spot[i].z);
        if (s >= 0 && v_receive > 0.5) {
            float lit_here = shadow_factor(s, v_world, n, n_dot_l);
            color += shadow_tint[s].rgb * (1.0 - lit_here) * c_diff;
            falloff *= lit_here;
        }
        color += light_radiance[i].rgb * falloff * n_dot_l * (diffuse + specular);
    }
    if (environment.x > 0.0) {
        // Diffuse from the irradiance; specular from the cube's mip for this roughness, through the BRDF table.
        vec3 diffuse_light = max(environment_irradiance(environment_direction(n)), vec3(0.0));
        vec3 r = environment_direction(reflect(-v, n));
        vec3 reflected = textureLod(samplerCube(lit3d_environment_texture, lit3d_environment_sampler), r, roughness * environment.y).rgb;
        vec2 ab = texture(sampler2D(lit3d_brdf_texture, lit3d_brdf_sampler), vec2(n_dot_v, roughness)).rg;
        color += (diffuse_light * c_diff + reflected * (f0 * ab.x + ab.y)) * environment.x;
    }
    color += emissive.rgb;
    frag_color = vec4(to_display(color), base.a);
}
@end
