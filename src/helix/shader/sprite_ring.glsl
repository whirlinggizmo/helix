/* SpriteRing (helix.shader.SpriteRing): a ring drawn across a sprite's quad, its color the sprite's tint: a selection under a unit, a target
 * on the ground, a spell's reach, a range. A sprite shader of the library: packed into the program by tools/pack_shader.py. It reads no texel,
 * only where it is across the sprite's region (helix_quad_uv), so the sprite's texture is only a quad's (a 1 x 1 white one does). */
@fs fs
@include_block helix_sprite
layout(binding=2) uniform sprite_ring_params {
    vec4 shape;  // x inner radius, y outer radius (fractions of the quad's half size), z edge softness (the same), w the fill inside's alpha
    vec4 motion; // x dashes round it (0 for none), y the gap's share of each dash, z spin in turns a second, w how much it pulses (0..1)
    vec4 pace;   // x pulses a second
};

void main() {
    vec2 p = helix_quad_uv() * 2.0 - 1.0;
    float r = length(p);
    // Edges smoothed over at least a pixel, at any size.
    float soft = max(shape.z, fwidth(r));
    float breathe = 1.0 + motion.w * 0.5 * sin(helix_time() * pace.x * 6.2831853);
    float inner = shape.x * breathe, outer = shape.y * breathe;
    float band = smoothstep(inner - soft, inner, r) * (1.0 - smoothstep(outer, outer + soft, r));
    if (motion.x >= 1.0) {
        // The dashes, turning: each dash's period around the ring, its gap at the end, its ends smoothed as its edges are.
        float turn = fract(atan(p.y, p.x) / 6.2831853 + 0.5 - helix_time() * motion.z) * floor(motion.x);
        float along = fract(turn), edge = max(fwidth(turn), 1e-4);
        band *= smoothstep(0.0, edge, along) * (1.0 - smoothstep(1.0 - motion.y - edge, 1.0 - motion.y, along));
    }
    float inside = (1.0 - smoothstep(inner - soft, inner, r)) * shape.w;
    vec4 tint = helix_tint();
    helix_output(tint.rgb, max(band, inside) * tint.a);
}
@end
