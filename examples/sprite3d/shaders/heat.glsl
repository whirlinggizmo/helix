/* Heat (examples/sprite3d): the example's own sprite shader, to show how one is written for a 3D view's sprites (docs/SHADERS.md). It
 * includes helix_sprite, so a sprite draws through it (new SpriteEffect(shader), Sprite3D.effect: the shader's sprite3D variant, which keeps
 * the sprite's alpha mode). It is packed into shaders/heat.hxshader in the assets, which the example loads (Shaders.load): by
 * tools/example.py for the examples, as a game's are by helix.tool.Build.packShaders. Its parameters are the uniform block at binding 2, set
 * by name (SpriteEffect.parameters). The flames shimmer: each row of the sprite's texels is pushed sideways along a sine rising with
 * the stage's time, most at the top and not at all at the bottom, read only inside the sprite's region (helix_region_texel_at). */
@fs fs
@include_block helix_sprite
layout(binding=2) uniform heat_params {
    float amplitude; // texels sideways at most, at the top
    float waves;     // whole waves up the sprite's height
    float speed;     // waves a second
};

void main() {
    vec2 across = helix_quad_uv();
    float phase = 6.2831853 * (across.y * waves + helix_time() * speed);
    float push = sin(phase) * amplitude * (1.0 - across.y) * helix_texel_size().x;
    vec4 c = helix_region_texel_at(helix_uv() + vec2(push, 0.0)) * helix_tint();
    helix_output(c.rgb, c.a);
}
@end
