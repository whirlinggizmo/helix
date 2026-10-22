
@vs {name}
layout(binding=0) uniform helix_surface_vs_params {
    mat4 helix_view_projection;
    vec4 helix_vs_info; // x seconds since the stage began
};
float helix_time() { return helix_vs_info.x; }
@include_block vertex
layout(location=0) in vec3 position;
layout(location=1) in vec3 normal;
layout(location=2) in vec2 uv;
layout(location=3) in vec4 tangent;
layout(location=4) in vec4 i_model0;
layout(location=5) in vec4 i_model1;
layout(location=6) in vec4 i_model2;
layout(location=7) in vec4 i_normal0;
layout(location=8) in vec4 i_normal1;
layout(location=9) in vec4 i_normal2;
layout(location=10) in vec4 i_tint;
layout(location=11) in vec4 i_lights0;
layout(location=12) in vec4 i_lights1;
{skin_inputs}out vec3 helix_v_normal;
out vec3 helix_v_model_position;
out vec3 helix_v_model_normal;
out vec4 helix_v_tangent;
out vec2 helix_v_uv;
out vec4 helix_v_tint;
out vec3 helix_v_world;
out float helix_v_receive;
flat out vec4 helix_v_lights0;
flat out vec4 helix_v_lights1;
void main() {
    vec3 moved = position, bent = normal, turned = tangent.xyz;
    // The vertex at rest in the model's own space, before skinning and the hook: what a pattern stuck to the surface is laid by.
    helix_v_model_position = position;
    helix_v_model_normal = normal;
{skin_call}    helix_vertex(moved, bent);
    vec4 p = vec4(moved, 1.0);
    vec3 world = vec3(dot(i_model0, p), dot(i_model1, p), dot(i_model2, p));
    gl_Position = helix_view_projection * vec4(world, 1.0);
    helix_v_normal = vec3(dot(i_normal0.xyz, bent), dot(i_normal1.xyz, bent), dot(i_normal2.xyz, bent));
    helix_v_tangent = vec4(dot(i_model0.xyz, turned), dot(i_model1.xyz, turned), dot(i_model2.xyz, turned), tangent.w * i_normal0.w);
    helix_v_uv = uv;
    helix_v_tint = i_tint;
    helix_v_world = world;
    helix_v_receive = i_normal1.w;
    helix_v_lights0 = i_lights0;
    helix_v_lights1 = i_lights1;
}
@end
