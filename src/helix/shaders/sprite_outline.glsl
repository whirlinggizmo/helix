/* SpriteOutline (helix.shaders.SpriteOutline): a sprite's shape outlined in a color, a width of texels out from its edge, where its region is
 * see-through. Eight reads around each pixel (the sides and the diagonals), each only inside the sprite's region, so a neighbor in an atlas
 * never shows. A sprite shader of the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_sprite
layout(binding=2) uniform sprite_outline_params {
    vec4 outline_color; // sRGB, its alpha how opaque
    float width;        // texels
};

void main() {
    vec4 own = helix_sprite_color();
    vec2 straight = width * helix_texel_size(), slanted = straight * 0.70710678, uv = helix_uv();
    // The most opaque of the eight around: the shape within the width.
    float near = max(max(max(helix_region_texel_at(uv + vec2(straight.x, 0.0)).a, helix_region_texel_at(uv - vec2(straight.x, 0.0)).a),
                         max(helix_region_texel_at(uv + vec2(0.0, straight.y)).a, helix_region_texel_at(uv - vec2(0.0, straight.y)).a)),
                     max(max(helix_region_texel_at(uv + slanted).a, helix_region_texel_at(uv - slanted).a),
                         max(helix_region_texel_at(uv + vec2(slanted.x, -slanted.y)).a, helix_region_texel_at(uv + vec2(-slanted.x, slanted.y)).a)));
    // Under the sprite's own texels, faded with its tint's alpha.
    float edge = near * outline_color.a * helix_tint().a * (1.0 - own.a);
    float alpha = own.a + edge;
    helix_output((own.rgb * own.a + outline_color.rgb * edge) / max(alpha, 1e-5), alpha);
}
@end
