/* Bloom (helix.shader.Bloom): light past a threshold spread around it. The frame (sRGB values, running past 1 in an HDR chain) is decoded to
 * linear light; its light past the threshold, with a soft knee, is drawn into half the frame's size with a 13-tap filter (Jimenez's, for
 * Call of Duty: Advanced Warfare, each group of four weighted by its brightness so a lone bright texel doesn't flicker), then down a chain of
 * halving sizes with the same filter; each level is added to the one below it drawn larger through a 3 x 3 tent, back up to half the frame,
 * and that is added to the frame times the intensity, encoded again as the frame was. One program for every step, chosen by `mode` (the
 * same for the whole draw, so the branches are uniform). A screen effect of the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform bloom_params {
    vec2 texel;       // the size of a texel of the texture read (helix_screen_texture), in its uv
    float mode;       // 0 the threshold and first step down, 1 a step down, 2 a step up, 3 added to the frame
    float threshold;  // linear light where the bloom starts
    float knee;       // the soft knee's half width, in linear light
    float intensity;  // the bloom's share added to the frame, divided by the levels summed
};
// The level being added to (a step up's), or the bloom (added to the frame).
layout(binding=1) uniform texture2D bloom_texture;
layout(binding=1) uniform sampler bloom_sampler;

vec3 decode(vec3 c) {
    c = max(c, vec3(0.0));
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 encode(vec3 c) {
    return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0031308)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

// The light past the threshold, the knee easing it in (Karis's curve).
vec3 bright(vec3 c) {
    float peak = max(c.r, max(c.g, c.b));
    float soft = clamp(peak - threshold + knee, 0.0, 2.0 * knee);
    soft = soft * soft / (4.0 * knee + 1e-5);
    return c * (max(soft, peak - threshold) / max(peak, 1e-5));
}

vec3 tap(vec2 uv, bool first) {
    vec3 c = helix_screen_color_at(uv).rgb;
    return first ? bright(decode(c)) : c;
}

// Karis's average: a group of four weighted by 1 / (1 + its brightness).
float karis(vec3 c) {
    return 1.0 / (1.0 + dot(c, vec3(0.2126, 0.7152, 0.0722)));
}

// The 13-tap filter, at this pixel of the half-size level, over the texture twice its size: five overlapping groups of four.
vec3 down(bool first) {
    vec2 uv = helix_screen_uv, t = texel;
    vec3 a = tap(uv + t * vec2(-2.0, -2.0), first), b = tap(uv + t * vec2(0.0, -2.0), first), c = tap(uv + t * vec2(2.0, -2.0), first);
    vec3 d = tap(uv + t * vec2(-2.0, 0.0), first), e = tap(uv, first), f = tap(uv + t * vec2(2.0, 0.0), first);
    vec3 g = tap(uv + t * vec2(-2.0, 2.0), first), h = tap(uv + t * vec2(0.0, 2.0), first), i = tap(uv + t * vec2(2.0, 2.0), first);
    vec3 j = tap(uv + t * vec2(-1.0, -1.0), first), k = tap(uv + t * vec2(1.0, -1.0), first);
    vec3 l = tap(uv + t * vec2(-1.0, 1.0), first), m = tap(uv + t * vec2(1.0, 1.0), first);
    vec3 g0 = (j + k + l + m) * 0.25, g1 = (a + b + d + e) * 0.25, g2 = (b + c + e + f) * 0.25;
    vec3 g3 = (d + e + g + h) * 0.25, g4 = (e + f + h + i) * 0.25;
    vec4 w = vec4(0.125);
    float w0 = 0.5;
    if (first) {
        w0 *= karis(g0);
        w *= vec4(karis(g1), karis(g2), karis(g3), karis(g4));
    }
    return (g0 * w0 + g1 * w.x + g2 * w.y + g3 * w.z + g4 * w.w) / (w0 + w.x + w.y + w.z + w.w);
}

// The 3 x 3 tent over the smaller level (helix_screen_texture), drawn at this pixel of the level twice its size.
vec3 tent() {
    vec2 uv = helix_screen_uv, t = texel;
    vec3 sum = helix_screen_color_at(uv).rgb * 4.0;
    sum += (helix_screen_color_at(uv + vec2(-t.x, 0.0)).rgb + helix_screen_color_at(uv + vec2(t.x, 0.0)).rgb
          + helix_screen_color_at(uv + vec2(0.0, -t.y)).rgb + helix_screen_color_at(uv + vec2(0.0, t.y)).rgb) * 2.0;
    sum += helix_screen_color_at(uv - t).rgb + helix_screen_color_at(uv + t).rgb
         + helix_screen_color_at(uv + vec2(t.x, -t.y)).rgb + helix_screen_color_at(uv + vec2(-t.x, t.y)).rgb;
    return sum * (1.0 / 16.0);
}

void main() {
    if (mode < 0.5) {
        helix_output(down(true), 1.0);
    } else if (mode < 1.5) {
        helix_output(down(false), 1.0);
    } else if (mode < 2.5) {
        helix_output(tent() + texture(sampler2D(bloom_texture, bloom_sampler), helix_screen_uv).rgb, 1.0);
    } else {
        vec4 frame = helix_screen_color();
        vec3 light = decode(frame.rgb) + texture(sampler2D(bloom_texture, bloom_sampler), helix_screen_uv).rgb * intensity;
        helix_output(encode(light), frame.a);
    }
}
@end
