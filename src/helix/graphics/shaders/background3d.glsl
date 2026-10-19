/* An environment behind a stage (render3d's Stage3D): one triangle over the viewport at the far plane, each pixel the environment's cube in its
 * view direction, a mip of it for blur, turned and scaled as the stage lights by it and tone mapped as its models are.
 *
 * background3d_vs_params: clip, the adapter's: clip space's x and y scales (y is -1 in a pass drawn flipped)
 * background3d_fs_params:
 *   inverse_view_projection  the camera's view-projection inverted (GL's -1..1 depth)
 *   environment              x intensity, y the mip (blur), z/w the cosine and sine of its rotation about +y
 *   tonemap                  as lit3d's: x mode (0 none, 1 Neutral, 2 ACES), y exposure's scale, z 1 in an HDR scene (written past 1, not
 *                            tone mapped) */
@vs background3d_vs
layout(binding=0) uniform background3d_vs_params {
    vec4 clip;
};
out vec2 v_ndc;
void main() {
    vec2 p = vec2(float((gl_VertexIndex << 1) & 2), float(gl_VertexIndex & 2)) * 2.0 - 1.0;
    v_ndc = p;
    // At the far plane: behind everything, passing a depth test against a cleared buffer.
    gl_Position = vec4(p.x, p.y * clip.y, 1.0, 1.0);
}
@end

@fs background3d_fs
layout(binding=1) uniform background3d_fs_params {
    mat4 inverse_view_projection;
    vec4 environment;
    vec4 tonemap;
};
layout(binding=0) uniform textureCube background3d_texture;
layout(binding=0) uniform sampler background3d_sampler;
in vec2 v_ndc;
out vec4 frag_color;

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

void main() {
    vec4 near_point = inverse_view_projection * vec4(v_ndc, -1.0, 1.0);
    vec4 far_point = inverse_view_projection * vec4(v_ndc, 1.0, 1.0);
    vec3 d = normalize(far_point.xyz / far_point.w - near_point.xyz / near_point.w);
    // Into the environment's frame: turned by -rotation about +y.
    d = vec3(environment.z * d.x - environment.w * d.z, d.y, environment.w * d.x + environment.z * d.z);
    vec3 color = textureLod(samplerCube(background3d_texture, background3d_sampler), d, environment.y).rgb * environment.x * tonemap.y;
    if (tonemap.z > 0.5) {
        // An HDR scene: the light as sRGB values, past 1 as well.
        color = max(color, vec3(0.0));
        frag_color = vec4(mix(color * 12.92, 1.055 * pow(max(color, vec3(0.0031308)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), color)), 1.0);
        return;
    }
    int mode = int(tonemap.x + 0.5);
    if (mode == 1) {
        color = tonemap_neutral(color);
    } else if (mode == 2) {
        color = tonemap_aces(color);
    }
    frag_color = vec4(linear_to_srgb(color), 1.0);
}
@end

@program background3d background3d_vs background3d_fs
