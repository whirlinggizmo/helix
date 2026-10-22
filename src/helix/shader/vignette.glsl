/* Vignette (helix.shader.Vignette): the frame shaded toward a color (black, say) from a radius out to its corners. A screen effect of the
 * library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform vignette_params {
    vec4 color;      // what the corners go toward: rgb sRGB, as the frame's
    float strength;  // how far they go there, 0..1
    float radius;    // where it starts, a share of the way from the middle to a corner
    float softness;  // how far beyond the radius it takes to reach its strength, the same share
};

void main() {
    vec4 frame = helix_screen_color();
    float r = length(helix_screen_uv - 0.5) * 1.41421356; // 0 in the middle, 1 in a corner
    float shade = smoothstep(radius, radius + max(softness, 1e-3), r) * strength;
    helix_output(mix(frame.rgb, color.rgb, shade), frame.a);
}
@end
