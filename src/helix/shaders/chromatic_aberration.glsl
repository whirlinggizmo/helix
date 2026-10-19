/* Chromatic aberration (helix.shaders.ChromaticAberration): red and blue read from a little inward and outward of where green is, more toward
 * the frame's edges, as a cheap lens splits colors. A screen effect of the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform chromatic_aberration_params {
    float amount; // how far red and blue part at the frame's edges, in its pixels each way
};

void main() {
    vec2 from_middle = helix_screen_uv - 0.5;
    // amount pixels at an edge (from the middle 0.5 of the way), less toward the middle.
    vec2 shift = from_middle * 2.0 * amount / helix_screen_size();
    vec4 middle = helix_screen_color();
    float red = helix_screen_color_at(helix_screen_uv - shift).r;
    float blue = helix_screen_color_at(helix_screen_uv + shift).b;
    helix_output(vec3(red, middle.g, blue), middle.a);
}
@end
