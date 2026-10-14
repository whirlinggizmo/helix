/* 3D sprites (render3d's Stage3D): one quad drawn once an instance. Each instance carries where its pivot goes and how it faces, its size
 * and pivot, its texture region, its own axes (for the facings that don't follow the camera), its alpha mode and its tint. The axes of the
 * facings that do are the camera's, the same for every sprite in a draw, so they're uniforms. Colors are sRGB values, as the 2D sprites'
 * are: texel times tint, unlit.
 *
 * i_position  xyz where the pivot goes, w facing: 0 the camera (its right and up), 1 upright (the camera's right flattened, world up),
 *             2 or more its own axes (i_right, i_up)
 * i_size      xy world size (scale included), zw the pivot (0..1 across, y down the texture)
 * i_region    the texture region: u0, v0 (top-left), u1, v1
 * i_right     xyz its own right (facing 2+)
 * i_up        xyz its own up (facing 2+), w the alpha mode: above 0 a mask's cutoff (texels below it discarded, the rest opaque), below 0
 *             opaque, 0 as is (blended or added by the pipeline)
 * i_tint      rgba, sRGB values */
@vs sprite3d_vs
layout(binding=0) uniform sprite3d_vs_params {
    mat4 view_projection;
    vec4 camera_right; // xyz: facing 0's right
    vec4 camera_up;    // xyz: facing 0's up
    vec4 upright;      // xyz: facing 1's right (its up is world y)
};
layout(location=0) in vec2 corner; // x -0.5 left .. 0.5 right, y -0.5 bottom .. 0.5 top
layout(location=1) in vec4 i_position;
layout(location=2) in vec4 i_size;
layout(location=3) in vec4 i_region;
layout(location=4) in vec4 i_right;
layout(location=5) in vec4 i_up;
layout(location=6) in vec4 i_tint;
out vec2 v_uv;
out vec4 v_tint;
out float v_alpha_mode;
void main() {
    vec3 right = i_right.xyz;
    vec3 up = i_up.xyz;
    if (i_position.w < 0.5) {
        right = camera_right.xyz;
        up = camera_up.xyz;
    } else if (i_position.w < 1.5) {
        right = upright.xyz;
        up = vec3(0.0, 1.0, 0.0);
    }
    // The pivot sits on the position: the quad reaches (1 - pivot.x) of its width right of it, and pivot.y of its height up (the pivot runs
    // down the texture).
    vec2 local = vec2((corner.x + 0.5 - i_size.z) * i_size.x, (corner.y - 0.5 + i_size.w) * i_size.y);
    vec3 world = i_position.xyz + right * local.x + up * local.y;
    gl_Position = view_projection * vec4(world, 1.0);
    v_uv = vec2(mix(i_region.x, i_region.z, corner.x + 0.5), mix(i_region.y, i_region.w, 0.5 - corner.y));
    v_tint = i_tint;
    v_alpha_mode = i_up.w;
}
@end

@fs sprite3d_fs
layout(binding=0) uniform texture2D sprite3d_texture;
layout(binding=0) uniform sampler sprite3d_sampler;
in vec2 v_uv;
in vec4 v_tint;
in float v_alpha_mode;
out vec4 frag_color;
void main() {
    frag_color = texture(sampler2D(sprite3d_texture, sprite3d_sampler), v_uv) * v_tint;
    if (v_alpha_mode > 0.0 && frag_color.a < v_alpha_mode) {
        discard;
    }
    if (v_alpha_mode != 0.0) {
        frag_color.a = 1.0;
    }
}
@end

@program sprite3d sprite3d_vs sprite3d_fs
