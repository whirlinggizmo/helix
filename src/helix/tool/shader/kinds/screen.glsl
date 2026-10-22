
@vs helix_screen_vs
// The adapter's: clip space's x and y scales (y is -1 in a pass drawn flipped, into a render target on GL).
layout(binding=0) uniform helix_screen_vs_params {
    vec4 helix_clip;
};
out vec2 helix_screen_uv;
void main() {
    // One triangle over the whole viewport; uv 0, 0 is the frame's top left.
    vec2 p = vec2(float((gl_VertexIndex << 1) & 2), float(gl_VertexIndex & 2)) * 2.0 - 1.0;
    helix_screen_uv = vec2(p.x + 1.0, 1.0 - p.y) * 0.5;
    gl_Position = vec4(p.x, p.y * helix_clip.y, 0.0, 1.0);
}
@end

@block helix_screen
// The frame being drawn over (its color values as the framebuffer holds them, sRGB; before an HDR chain's tone mapping, past 1 too), its
// size and the time.
layout(binding=1) uniform helix_screen_params {
    vec4 helix_screen_info; // xy the frame's size in pixels, z seconds: the stage's time
};
layout(binding=0) uniform texture2D helix_screen_texture;
layout(binding=0) uniform sampler helix_screen_sampler;
in vec2 helix_screen_uv;
out vec4 helix_frag_color;
// The frame's color here.
vec4 helix_screen_color() { return texture(sampler2D(helix_screen_texture, helix_screen_sampler), helix_screen_uv); }
// The frame's color at uv (0, 0 its top left).
vec4 helix_screen_color_at(vec2 uv) { return texture(sampler2D(helix_screen_texture, helix_screen_sampler), uv); }
vec2 helix_screen_size() { return helix_screen_info.xy; }
float helix_time() { return helix_screen_info.z; }
void helix_output(vec3 color, float alpha) { helix_frag_color = vec4(color, alpha); }
@end
