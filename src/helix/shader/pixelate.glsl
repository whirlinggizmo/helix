/* Pixelate (helix.shader.Pixelate): the frame in square cells, each the color at its middle. A screen effect of the library: packed into the
 * program by tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform pixelate_params {
    float cell_size; // a cell's side, in the frame's pixels
};

void main() {
    vec2 size = helix_screen_size();
    vec2 cell = vec2(max(cell_size, 1.0));
    vec2 middle = (floor(helix_screen_uv * size / cell) + 0.5) * cell / size;
    vec4 frame = helix_screen_color_at(middle);
    helix_output(frame.rgb, frame.a);
}
@end
