/* CRT scanlines (examples/postprocess): dark lines across the frame, a slight color shift left and right, and a slow flicker; a second screen
 * effect, to show a chain. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform params {
    float lines;    // dark lines down the frame
    float darkness; // how dark they go (0..1)
    float offset;   // the color shift, in pixels
    float flicker;  // brightness wobble over time (0..1)
};

void main() {
    vec2 texel = 1.0 / helix_screen_size();
    // Red and blue from a little left and right of this pixel.
    vec3 color = vec3(helix_screen_color_at(helix_screen_uv - vec2(offset * texel.x, 0.0)).r,
                      helix_screen_color().g,
                      helix_screen_color_at(helix_screen_uv + vec2(offset * texel.x, 0.0)).b);
    float line = 0.5 + 0.5 * cos(helix_screen_uv.y * max(lines, 1.0) * 6.2831853);
    color *= 1.0 - clamp(darkness, 0.0, 1.0) * line;
    color *= 1.0 + clamp(flicker, 0.0, 1.0) * 0.06 * sin(helix_time() * 11.0);
    helix_output(color, 1.0);
}
@end
