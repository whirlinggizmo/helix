/* Lit models (render3d's Stage3D): glTF metallic-roughness materials lit by up to 4 lights, tone mapped (Khronos PBR Neutral) and written as
 * sRGB. The BRDF follows glTF 2.0's appendix B: Lambert diffuse, GGX / Smith height-correlated specular, Schlick Fresnel. Each instance's
 * placement (the model matrix's rows), its normals' matrix (the inverse transpose's rows) and its tint come from the instance buffer, so
 * placements alike in everything else are one draw.
 *
 * Color space: the framebuffer holds sRGB values. The base color texture is decoded from sRGB; the normal map is linear (tangent space,
 * green up, as glTF's); factors, tints, emissive and light radiance are linear; lighting happens in linear space. i_normal0.w is the
 * tangents' handedness: -1 where the placement mirrors them.
 *
 * lit3d_vs_params: view_projection
 * lit3d_fs_params:
 *   camera_position    xyz
 *   ambient            rgb, linear, times intensity
 *   base_color         linear rgba, the material's
 *   pbr                x metallic, y roughness, z 1 = lit (0 = unlit), w the number of lights (0..4)
 *   emissive           rgb linear light the surface gives off, w the normal map's strength
 *   light_position[i]  xyz position, w range (0: unlimited)
 *   light_direction[i] xyz the direction the light travels, w type (0 directional, 1 point)
 *   light_radiance[i]  rgb color times intensity, linear */
@vs lit3d_vs
layout(binding=0) uniform lit3d_vs_params {
    mat4 view_projection;
};
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
void main() {
    vec4 p = vec4(position, 1.0);
    vec3 world = vec3(dot(i_model0, p), dot(i_model1, p), dot(i_model2, p));
    gl_Position = view_projection * vec4(world, 1.0);
    v_normal = vec3(dot(i_normal0.xyz, normal), dot(i_normal1.xyz, normal), dot(i_normal2.xyz, normal));
    v_tangent = vec4(dot(i_model0.xyz, tangent.xyz), dot(i_model1.xyz, tangent.xyz), dot(i_model2.xyz, tangent.xyz), tangent.w * i_normal0.w);
    v_uv = uv;
    v_tint = i_tint;
    v_world = world;
}
@end

@fs lit3d_fs
const float PI = 3.14159265359;
layout(binding=1) uniform lit3d_fs_params {
    vec4 camera_position;
    vec4 ambient;
    vec4 base_color;
    vec4 pbr;
    vec4 emissive;
    vec4 light_position[4];
    vec4 light_direction[4];
    vec4 light_radiance[4];
};
layout(binding=0) uniform texture2D lit3d_base_texture;
layout(binding=0) uniform sampler lit3d_base_sampler;
layout(binding=1) uniform texture2D lit3d_normal_texture;
layout(binding=1) uniform sampler lit3d_normal_sampler;
in vec3 v_normal;
in vec4 v_tangent;
in vec2 v_uv;
in vec4 v_tint;
in vec3 v_world;
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

float attenuation(float d, float range) {
    float inv_sq = 1.0 / max(d * d, 0.01);
    if (range <= 0.0) {
        return inv_sq;
    }
    float r = d / range;
    float w = clamp(1.0 - r * r * r * r, 0.0, 1.0);
    return w * w * inv_sq;
}

void main() {
    vec4 texel = texture(sampler2D(lit3d_base_texture, lit3d_base_sampler), v_uv);
    vec4 base = vec4(srgb_to_linear(texel.rgb), texel.a) * base_color * v_tint;
    if (pbr.z < 0.5) {
        frag_color = vec4(linear_to_srgb(tonemap_neutral(base.rgb + emissive.rgb)), base.a);
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
        color += light_radiance[i].rgb * falloff * n_dot_l * (diffuse + specular);
    }
    color += emissive.rgb;
    frag_color = vec4(linear_to_srgb(tonemap_neutral(color)), base.a);
}
@end

@program lit3d lit3d_vs lit3d_fs
