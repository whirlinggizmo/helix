/* What the flat programs share, included by flat3d.glsl (static models) and skinnedflat3d.glsl (skinned ones): a model's passes (render3d's
 * ModelPass, helix.shader' Outline and Silhouette), the model drawn again in one flat color after the stage's opaque models.
 *
 * Each vertex is placed as the lit models' are, from the instance records the stage wrote for the model, its position and normal from the
 * mesh's pass vertices (Mesh.passVertices: the normal averaged over every vertex at that position, so where the model's normals split at a
 * hard edge its copies move together and the shell stays closed), then pushed out along that normal in the world by push.x world units (an
 * outline's shell). The color is a display color (sRGB, 0..1 rgba), written as it is: into an HDR scene too, as sprites are.
 *
 * flat3d_vs_params: view_projection; push (x world units along the normal)
 * flat3d_fs_params: color (sRGB rgba) */

@block flat3d_vertex
layout(location=0) in vec3 position;
layout(location=1) in vec3 normal;
layout(location=2) in vec4 i_model0;
layout(location=3) in vec4 i_model1;
layout(location=4) in vec4 i_model2;
layout(location=5) in vec4 i_normal0;
layout(location=6) in vec4 i_normal1;
layout(location=7) in vec4 i_normal2;
// Places a vertex (its position and averaged normal in the model's space) by its instance's record, pushed as the pass asks.
void flat3d_place(vec3 placed, vec3 bent) {
    vec4 p = vec4(placed, 1.0);
    vec3 world = vec3(dot(i_model0, p), dot(i_model1, p), dot(i_model2, p));
    vec3 n = vec3(dot(i_normal0.xyz, bent), dot(i_normal1.xyz, bent), dot(i_normal2.xyz, bent));
    float length_sq = dot(n, n);
    world += (length_sq > 1e-12 ? n * inversesqrt(length_sq) : vec3(0.0)) * push.x;
    gl_Position = view_projection * vec4(world, 1.0);
}
@end

@block flat3d_fragment
out vec4 frag_color;
void main() {
    frag_color = color;
}
@end
