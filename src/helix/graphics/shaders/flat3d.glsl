/* A model's flat passes (render3d's Stage3D): flat3d_shared.glsl's stages, a static model's vertices placed as they are. */
@include flat3d_shared.glsl

@vs flat3d_vs
layout(binding=0) uniform flat3d_vs_params {
    mat4 view_projection;
    vec4 push;
};
@include_block flat3d_vertex
void main() {
    flat3d_place(position, normal);
}
@end

@fs flat3d_fs
layout(binding=1) uniform flat3d_fs_params {
    vec4 color;
};
@include_block flat3d_fragment
@end

@program flat3d flat3d_vs flat3d_fs
