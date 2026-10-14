/* Lit models (render3d's Stage3D): lit3d_shared.glsl's stages, a static model's vertices placed as they are. */
@include lit3d_shared.glsl

@vs lit3d_vs
layout(binding=0) uniform lit3d_vs_params {
    mat4 view_projection;
};
@include_block lit3d_vertex
void main() {
    lit3d_place(position, normal, tangent.xyz);
}
@end

@fs lit3d_fs
layout(binding=1) uniform lit3d_fs_params {
@include_block lit3d_fs_members
};
@include_block lit3d_fragment
@end

@program lit3d lit3d_vs lit3d_fs
