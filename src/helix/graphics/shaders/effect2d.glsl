/* 2D sprites drawn through a sprite effect (helix.graphics.SpriteEffect, Batch2D.effect): the sprite kind of shader. Its vertex stage and the
 * block a sprite shader's fragment stage includes (@include_block helix_sprite) are the kind's own: tools/pack_shader.py packs them with
 * every sprite shader, the shader library's and an app's. The program here draws the sprite as the framework's sprite2d does, and gives the
 * vertices' layout (Effect2DProgram): sprite2d's, and each vertex its sprite's texture region.
 *
 * position  clip space before the adapter's scale (block 0)
 * uv        the texture coordinate
 * color     the tint, sRGB values; an alpha over 1.5 marks a distance-field texture (text: alpha 0.5 is the outline), tinted by the alpha
 *           less 2, as sprite2d's does
 * region    the sprite's region of its texture: u0, v0 (its top-left), u1, v1; the same at each of its vertices */
@vs effect2d_vs
// The adapter's: clip space's x and y scales (y is -1 in a pass drawn flipped, into a render target on GL).
layout(binding=0) uniform helix_sprite_vs_params {
    vec4 helix_clip;
};
layout(location=0) in vec2 position;
layout(location=1) in vec2 uv;
layout(location=2) in vec4 color;
layout(location=3) in vec4 region;
out vec2 helix_sprite_v_uv;
out vec4 helix_sprite_v_tint;
flat out vec4 helix_sprite_v_region;
void main() {
    gl_Position = vec4(position * helix_clip.xy, 0.0, 1.0);
    helix_sprite_v_uv = uv;
    helix_sprite_v_tint = color;
    helix_sprite_v_region = region;
}
@end

@block helix_sprite
// The batch's: the sprite's texture's size and the time.
layout(binding=1) uniform helix_sprite_params {
    vec4 helix_sprite_info; // xy the texture's size in texels, z seconds (the batch's time)
};
layout(binding=0) uniform texture2D helix_sprite_texture;
layout(binding=0) uniform sampler helix_sprite_sampler;
in vec2 helix_sprite_v_uv;
in vec4 helix_sprite_v_tint;
flat in vec4 helix_sprite_v_region;
out vec4 helix_frag_color;

// The texture coordinate here.
vec2 helix_uv() { return helix_sprite_v_uv; }
// The sprite's region of its texture: xy its top-left's texture coordinate, zw its bottom-right's.
vec4 helix_region() { return vec4(min(helix_sprite_v_region.xy, helix_sprite_v_region.zw), max(helix_sprite_v_region.xy, helix_sprite_v_region.zw)); }
// Where here is across the sprite's region, 0, 0 its top-left to 1, 1 its bottom-right (0 across a region with no size).
vec2 helix_quad_uv() {
    vec2 size = helix_sprite_v_region.zw - helix_sprite_v_region.xy;
    return vec2(abs(size.x) > 1e-8 ? (helix_sprite_v_uv.x - helix_sprite_v_region.x) / size.x : 0.0,
                abs(size.y) > 1e-8 ? (helix_sprite_v_uv.y - helix_sprite_v_region.y) / size.y : 0.0);
}
// The texture's size in texels.
vec2 helix_texture_size() { return helix_sprite_info.xy; }
// One texel's size in texture coordinates.
vec2 helix_texel_size() { return 1.0 / max(helix_sprite_info.xy, vec2(1.0)); }
// Seconds: the batch's time (Batch2D.time).
float helix_time() { return helix_sprite_info.z; }
// The sprite's tint: sRGB values, alpha 0..1.
vec4 helix_tint() { return helix_sprite_v_tint.a > 1.5 ? vec4(helix_sprite_v_tint.rgb, helix_sprite_v_tint.a - 2.0) : helix_sprite_v_tint; }
// The texture at uv, untinted.
vec4 helix_texel_at(vec2 uv) { return texture(sampler2D(helix_sprite_texture, helix_sprite_sampler), uv); }
// The texture at uv when it is inside the sprite's region, read no nearer its edge than half a texel (so a linear read takes nothing from a
// neighbor in an atlas); transparent black outside it.
vec4 helix_region_texel_at(vec2 uv) {
    vec4 r = helix_region();
    if (uv.x < r.x || uv.y < r.y || uv.x > r.z || uv.y > r.w) return vec4(0.0);
    vec2 half_texel = 0.5 * helix_texel_size();
    return helix_texel_at(clamp(uv, min(r.xy + half_texel, (r.xy + r.zw) * 0.5), max(r.zw - half_texel, (r.xy + r.zw) * 0.5)));
}
// The sprite's color here as the framework draws it: its texel times its tint (a distance field's coverage in its tint, for text).
vec4 helix_sprite_color() {
    vec4 texel = helix_texel_at(helix_sprite_v_uv);
    if (helix_sprite_v_tint.a > 1.5) {
        // Distance-field text, as sprite2d draws it: alpha 0.5 is the outline, its edge smoothed over about a pixel at any scale.
        float w = max(fwidth(texel.a) * 0.75, 1e-4);
        vec2 dx = dFdx(helix_sprite_v_uv) * 0.25, dy = dFdy(helix_sprite_v_uv) * 0.25;
        float coverage = smoothstep(0.5 - w, 0.5 + w, helix_texel_at(helix_sprite_v_uv + dx + dy).a)
            + smoothstep(0.5 - w, 0.5 + w, helix_texel_at(helix_sprite_v_uv + dx - dy).a)
            + smoothstep(0.5 - w, 0.5 + w, helix_texel_at(helix_sprite_v_uv - dx + dy).a)
            + smoothstep(0.5 - w, 0.5 + w, helix_texel_at(helix_sprite_v_uv - dx - dy).a);
        return vec4(helix_sprite_v_tint.rgb, coverage * 0.25 * (helix_sprite_v_tint.a - 2.0));
    }
    return texel * helix_sprite_v_tint;
}
// Writes the color here: sRGB values and alpha, blended over what is drawn as the batch blends.
void helix_output(vec3 color, float alpha) { helix_frag_color = vec4(color, alpha); }
@end

@fs effect2d_fs
@include_block helix_sprite
void main() {
    vec4 c = helix_sprite_color();
    helix_output(c.rgb, c.a);
}
@end

@program effect2d effect2d_vs effect2d_fs
