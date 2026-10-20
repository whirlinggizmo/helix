/* Shadow maps' depth (render3d's Stage3D): the casters as a light sees them, depth only. A model's vertices are the lit models' own (Lit3DProgram's
 * stride), of which this reads the position; each instance's placement (the model matrix's rows) comes from the instance buffer, so casters
 * alike in mesh are one draw.
 *
 * depth3d_vs_params: light_view_projection, world to the light's clip space */
@vs depth3d_vs
layout(binding=0) uniform depth3d_vs_params {
    mat4 light_view_projection;
};
layout(location=0) in vec3 position;
layout(location=1) in vec4 i_model0;
layout(location=2) in vec4 i_model1;
layout(location=3) in vec4 i_model2;
void main() {
    vec4 p = vec4(position, 1.0);
    gl_Position = light_view_projection * vec4(dot(i_model0, p), dot(i_model1, p), dot(i_model2, p), 1.0);
}
@end

@fs depth3d_fs
void main() {
}
@end

@program depth3d depth3d_vs depth3d_fs
