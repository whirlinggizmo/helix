/* SpriteFlash (helix.shader.SpriteFlash): a color mixed over a sprite's, its alpha kept, as a hit flashes it. A sprite shader of the library:
 * packed into the program by ShaderPacker (tools/gen_code.py). */
@fs fs
@include_block helix_sprite
layout(binding=2) uniform sprite_flash_params {
    vec4 flash; // rgb sRGB, a how much of it now (its color's alpha times the amount)
};

void main() {
    vec4 own = helix_sprite_color();
    helix_output(mix(own.rgb, flash.rgb, clamp(flash.a, 0.0, 1.0)), own.a);
}
@end
