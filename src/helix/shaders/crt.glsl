/* CRT (helix.shaders.Crt): an old monitor's picture: its glass curved (the frame bent outward, black beyond it), dark lines between its rows,
 * an aperture grille (columns of red, green and blue), and a flicker. The grille's channel is chosen arithmetically, not by an index. A
 * screen effect of the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform crt_params {
    float lines;      // the rows down the frame
    float darkness;   // how dark the lines between them go, 0..1
    float curvature;  // how far the glass bends, 0..1
    float mask;       // how strong the grille is, 0..1
    float mask_size;  // a grille column's width, in the frame's pixels
    float flicker;    // the brightness's wobble over time, 0..1
};

void main() {
    // Bent: the further from the middle, the further out it reads.
    vec2 centered = helix_screen_uv * 2.0 - 1.0;
    centered *= 1.0 + curvature * 0.25 * dot(centered, centered);
    vec2 uv = centered * 0.5 + 0.5;
    vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
    vec4 frame = helix_screen_color_at(clamp(uv, 0.0, 1.0));
    vec3 color = frame.rgb;
    float line = 0.5 + 0.5 * cos(uv.y * max(lines, 1.0) * 6.2831853);
    color *= 1.0 - darkness * line;
    // The grille: each column a channel in turn, lit alone; on average a third as bright, so raised again.
    float column = mod(floor(helix_screen_uv.x * helix_screen_size().x / max(mask_size, 1.0)), 3.0);
    vec3 grille = clamp(1.0 - abs(vec3(0.0, 1.0, 2.0) - column), 0.0, 1.0);
    color *= mix(vec3(1.0), grille * 2.0 + 0.35, mask);
    color *= 1.0 + flicker * 0.06 * sin(helix_time() * 11.0);
    helix_output(color * inside.x * inside.y, frame.a);
}
@end
