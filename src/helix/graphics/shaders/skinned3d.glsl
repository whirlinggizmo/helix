/* Skinned lit models (render3d's Stage3D): lit3d_shared.glsl's stages, each vertex first moved by its joints (skinning.glsl), its joint indices
 * and weights from a buffer of their own beside the vertices, its model's first joint from its record (i_normal2.w). */
@include lit3d_shared.glsl
@include skinning.glsl

@vs skinned3d_vs
layout(binding=0) uniform skinned3d_vs_params {
    mat4 view_projection;
};
@include_block lit3d_vertex
layout(location=13) in vec4 joints;
layout(location=14) in vec4 weights;
layout(binding=5) uniform texture2D skinned3d_joint_texture;
layout(binding=5) uniform sampler skinned3d_joint_sampler;
@image_sample_type skinned3d_joint_texture unfilterable_float
@sampler_type skinned3d_joint_sampler nonfiltering
vec4 joint_texel(ivec2 at) {
    return texelFetch(sampler2D(skinned3d_joint_texture, skinned3d_joint_sampler), at, 0);
}
@include_block skinning
void main() {
    vec3 moved = position, bent = normal, turned = tangent.xyz;
    skin(int(i_normal2.w + 0.5), joints, weights, moved, bent, turned);
    lit3d_place(moved, bent, turned);
}
@end

@fs skinned3d_fs
layout(binding=1) uniform skinned3d_fs_params {
@include_block lit3d_fs_members
};
@include_block lit3d_fragment
@end

@program skinned3d skinned3d_vs skinned3d_fs
