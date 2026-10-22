/* Unlit (helix.shader.Unlit): the material's base color and texture times a color, and its emission, with no light; the stage's exposure and
 * tone mapping apply, as to a material that isn't lit. A surface shader of the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_surface
layout(binding=2) uniform unlit_params {
    vec4 color; // rgb sRGB, as the material's colors are; a
};

void main() {
    vec4 base = helix_base() * vec4(helix_srgb_to_linear(color.rgb), color.a);
    helix_output(base.rgb + helix_emissive(), base.a);
}
@end
