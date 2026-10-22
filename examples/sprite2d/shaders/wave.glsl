/* Wave (examples/sprite2d): the example's own sprite shader, to show how one is written (docs/SHADERS.md). It includes helix_sprite, so a
 * node's own drawing goes through it (new SpriteEffect(shader), Node2D.effect). It is packed into shaders/wave.hxshader in the assets, which
 * the example loads (Shaders.load): by tools/example.py for the examples, as a game's are by helix.tool.Build.packShaders (and again on save
 * in the dev loop). Its parameters are the uniform block at binding 2, set by name (SpriteEffect.parameters). Each row of the sprite's texels is pushed sideways
 * along a sine down its height that travels with the batch's time, a flag in the wind, read only inside the sprite's region
 * (helix_region_texel_at), so a sheet's neighboring cells never show. It reads the texture away from where the sprite is, so it isn't for
 * text: a distance-field glyph is drawn by helix_sprite_color, which reads where the sprite is. */
@fs fs
@include_block helix_sprite
layout(binding=2) uniform wave_params {
    float amplitude; // texels sideways at most
    float waves;     // whole waves down the sprite's height
    float speed;     // waves a second
};

void main() {
    float phase = 6.2831853 * (helix_quad_uv().y * waves - helix_time() * speed);
    vec4 c = helix_region_texel_at(helix_uv() + vec2(sin(phase) * amplitude * helix_texel_size().x, 0.0)) * helix_tint();
    helix_output(c.rgb, c.a);
}
@end
