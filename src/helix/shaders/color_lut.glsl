/* Color LUT (helix.shaders.ColorLut): the frame graded through a 32 x 32 x 32 color cube laid out as a 1024 x 32 strip: blue chooses one of 32
 * squares left to right, red runs across a square, green down it; each texel's color what that color becomes. A color is read between the
 * two squares its blue falls between, each read half a texel in from the square's edges, so the filtering never reaches into the next
 * square. Over the tone-mapped frame, its sRGB values as they are. A screen effect of the library: packed into the program by
 * tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform color_lut_params {
    float amount; // how much of the grade, 0..1
};
layout(binding=1) uniform texture2D lut_texture;
layout(binding=1) uniform sampler lut_sampler;

vec3 square(vec2 rg, float b) {
    vec2 at = vec2((b * 32.0 + rg.x * 31.0 + 0.5) / 1024.0, (rg.y * 31.0 + 0.5) / 32.0);
    return textureLod(sampler2D(lut_texture, lut_sampler), at, 0.0).rgb;
}

void main() {
    vec4 frame = helix_screen_color();
    vec3 c = clamp(frame.rgb, 0.0, 1.0);
    float b = c.b * 31.0;
    float b0 = floor(b);
    float b1 = min(b0 + 1.0, 31.0);
    vec3 graded = mix(square(c.rg, b0), square(c.rg, b1), b - b0);
    helix_output(mix(frame.rgb, graded, amount), frame.a);
}
@end
