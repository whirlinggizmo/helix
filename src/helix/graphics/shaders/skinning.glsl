/* Skinning, included by the skinned programs (skinned3d.glsl, skinneddepth3d.glsl): a vertex moved by up to four joints of a joint texture,
 * which a program reads through its own joint_texel(at) (its texture's binding differs). The texture is RGBA32F, 1024 texels a row; joint j
 * is the three texels from texel 3j, its matrix's rows (an affine matrix's top three: joint space moved into the skinned model's own, its
 * inverse bind matrix applied). A vertex's joints are indices from its model's first joint, its weights summing to 1. */
@block skinning
// Joint j's matrix: three texels from texel 3j, its rows.
void joint_rows(int j, out vec4 r0, out vec4 r1, out vec4 r2) {
    int t = j * 3;
    r0 = joint_texel(ivec2(t % 1024, t / 1024));
    r1 = joint_texel(ivec2((t + 1) % 1024, (t + 1) / 1024));
    r2 = joint_texel(ivec2((t + 2) % 1024, (t + 2) / 1024));
}

// Moves position, normal and tangent (the model's space) by the weighted joints from first: the joints' matrices blended, then applied.
void skin(int first, vec4 joints, vec4 weights, inout vec3 position, inout vec3 normal, inout vec3 tangent) {
    vec4 m0 = vec4(0.0), m1 = vec4(0.0), m2 = vec4(0.0), r0, r1, r2;
    for (int i = 0; i < 4; i++) {
        float w = weights[i];
        if (w > 0.0) {
            joint_rows(first + int(joints[i] + 0.5), r0, r1, r2);
            m0 += r0 * w;
            m1 += r1 * w;
            m2 += r2 * w;
        }
    }
    vec4 p = vec4(position, 1.0);
    position = vec3(dot(m0, p), dot(m1, p), dot(m2, p));
    normal = vec3(dot(m0.xyz, normal), dot(m1.xyz, normal), dot(m2.xyz, normal));
    tangent = vec3(dot(m0.xyz, tangent), dot(m1.xyz, tangent), dot(m2.xyz, tangent));
}
@end
