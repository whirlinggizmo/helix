/* Skinned casters' shadow-map depth (render3d's Stage3D): as depth3d.glsl, each vertex first moved by its joints (skinning.glsl), its joint
 * indices and weights from the skin buffer, its model's first joint the x of its record's fourth row.
 *
 * skinneddepth3d_vs_params: light_view_projection, world to the light's clip space */
@include skinning.glsl

@vs skinneddepth3d_vs
layout(binding=0) uniform skinneddepth3d_vs_params {
    mat4 light_view_projection;
};
layout(location=0) in vec3 position;
layout(location=1) in vec4 i_model0;
layout(location=2) in vec4 i_model1;
layout(location=3) in vec4 i_model2;
layout(location=4) in vec4 i_skin;
layout(location=5) in vec4 joints;
layout(location=6) in vec4 weights;
layout(binding=0) uniform texture2D skinneddepth3d_joint_texture;
layout(binding=0) uniform sampler skinneddepth3d_joint_sampler;
@image_sample_type skinneddepth3d_joint_texture unfilterable_float
@sampler_type skinneddepth3d_joint_sampler nonfiltering
vec4 joint_texel(ivec2 at) {
    return texelFetch(sampler2D(skinneddepth3d_joint_texture, skinneddepth3d_joint_sampler), at, 0);
}
@include_block skinning
void main() {
    vec3 moved = position, bent = vec3(0.0, 1.0, 0.0), turned = vec3(1.0, 0.0, 0.0);
    skin(int(i_skin.x + 0.5), joints, weights, moved, bent, turned);
    vec4 p = vec4(moved, 1.0);
    gl_Position = light_view_projection * vec4(dot(i_model0, p), dot(i_model1, p), dot(i_model2, p), 1.0);
}
@end

@fs skinneddepth3d_fs
void main() {
}
@end

@program skinneddepth3d skinneddepth3d_vs skinneddepth3d_fs
