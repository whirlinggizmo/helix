/* Tonemap (helix.shader.Tonemap): an HDR scene's tone mapping, at the end of a PostProcess chain. The frame holds a stage's light after its
 * exposure as sRGB values running past 1 (the sRGB curve carried on); it is decoded to linear light, brought into 0..1 by the stage's mode
 * as Stage3D does drawing straight to the screen (0 none, clamped; 1 Khronos PBR Neutral; 2 ACES, Narkowicz's fit) and written as the
 * screen's sRGB. A screen effect of the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform tonemap_params {
    float mode; // 0 none, 1 Neutral, 2 ACES
};

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
    vec4 frame = helix_screen_color();
    vec3 c = max(frame.rgb, vec3(0.0));
    vec3 color = mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
    int m = int(mode + 0.5);
    if (m == 1) {
        color = tonemap_neutral(color);
    } else if (m == 2) {
        color = tonemap_aces(color);
    }
    color = clamp(color, vec3(0.0), vec3(1.0));
    helix_frag_color = vec4(mix(color * 12.92, 1.055 * pow(max(color, vec3(0.0031308)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), color)), frame.a);
}
@end
