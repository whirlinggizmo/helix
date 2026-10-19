/* Blur (helix.shaders.Blur): a Gaussian blur in two passes, across then down, each 17 taps spread over the radius either side (its standard
 * deviation a third of the radius). The first pass draws into a texture a fraction of the frame's size, which the second reads drawn
 * larger. Its taps are written out with their weights (no array indexed by a loop), as some mobile GPUs' compilers want. A screen effect of
 * the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform blur_params {
    vec2 spacing; // between taps, in the read texture's uv: the radius over 8, across or down
};

vec3 pair(float k, float weight) {
    return (helix_screen_color_at(helix_screen_uv - spacing * k).rgb + helix_screen_color_at(helix_screen_uv + spacing * k).rgb) * weight;
}

void main() {
    vec4 middle = helix_screen_color();
    vec3 sum = middle.rgb * 0.1498049;
    sum += pair(1.0, 0.1396335);
    sum += pair(2.0, 0.1130786);
    sum += pair(3.0, 0.0795608);
    sum += pair(4.0, 0.0486345);
    sum += pair(5.0, 0.0258296);
    sum += pair(6.0, 0.0119184);
    sum += pair(7.0, 0.0047780);
    sum += pair(8.0, 0.0016642);
    helix_output(sum, middle.a);
}
@end
