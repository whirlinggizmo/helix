/* PaletteSwap (helix.shader.PaletteSwap): a sprite drawn in a palette's colors, its red channel (0..255) the column of a palette texture's
 * row, the row a variant; the sprite's alpha kept, both times the tint. Both read texel by texel at exact texel centers, whatever their
 * sampling, so an index is never blended with its neighbor. A sprite shader of the library: packed into the program by ShaderPacker (tools/gen_code.py). */
@fs fs
@include_block helix_sprite
layout(binding=2) uniform palette_swap_params {
    float row; // the palette's row, 0 its top
};
layout(binding=1) uniform texture2D palette;
layout(binding=1) uniform sampler palette_sampler;

void main() {
    // The sprite's texel here, read where it lies whatever the sprite's sampling, within its region.
    vec4 r = helix_region();
    vec2 size = helix_texture_size();
    ivec2 first = ivec2(floor(r.xy * size + 0.5)), last = max(ivec2(floor(r.zw * size + 0.5)) - 1, first);
    vec4 texel = texelFetch(sampler2D(helix_sprite_texture, helix_sprite_sampler), clamp(ivec2(floor(helix_uv() * size)), first, last), 0);
    ivec2 colors = textureSize(sampler2D(palette, palette_sampler), 0);
    ivec2 at = ivec2(clamp(int(floor(texel.r * 255.0 + 0.5)), 0, colors.x - 1), clamp(int(floor(row + 0.5)), 0, colors.y - 1));
    vec4 color = texelFetch(sampler2D(palette, palette_sampler), at, 0);
    vec4 tint = helix_tint();
    helix_output(color.rgb * tint.rgb, texel.a * color.a * tint.a);
}
@end
