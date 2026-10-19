/* A skinned model's flat passes (render3d's Stage3D): flat3d_shared.glsl's stages, each vertex first moved by its joints (skinning.glsl), its
 * joint indices and weights from the skin buffer, its model's first joint from its record (i_normal2.w), as the skinned lit program's. */
@include flat3d_shared.glsl
@include skinning.glsl

@vs skinnedflat3d_vs
layout(binding=0) uniform skinnedflat3d_vs_params {
    mat4 view_projection;
    vec4 push;
};
@include_block flat3d_vertex
layout(location=8) in vec4 joints;
layout(location=9) in vec4 weights;
layout(binding=0) uniform texture2D skinnedflat3d_joint_texture;
layout(binding=0) uniform sampler skinnedflat3d_joint_sampler;
@image_sample_type skinnedflat3d_joint_texture unfilterable_float
@sampler_type skinnedflat3d_joint_sampler nonfiltering
vec4 joint_texel(ivec2 at) {
    return texelFetch(sampler2D(skinnedflat3d_joint_texture, skinnedflat3d_joint_sampler), at, 0);
}
@include_block skinning
void main() {
    vec3 moved = position, bent = normal, turned = vec3(1.0, 0.0, 0.0);
    skin(int(i_normal2.w + 0.5), joints, weights, moved, bent, turned);
    flat3d_place(moved, bent);
}
@end

@fs skinnedflat3d_fs
layout(binding=1) uniform skinnedflat3d_fs_params {
    vec4 color;
};
@include_block flat3d_fragment
@end

@program skinnedflat3d skinnedflat3d_vs skinnedflat3d_fs
