// <helix/raylib/shaders/skinning.glsl>: skinning on the GPU, for a vertex stage of helix-raylib's.
//
// It declares the bone inputs a skinned mesh feeds, vertexBoneIds and vertexBoneWeights (four bones a vertex, as raylib's), the frame's
// bone palette (uniform sampler2D bonePalette) and the draw's first bone in it plus one (uniform int boneOffset, 0 for a draw without
// bones), and two functions:
// mat4 helixSkin() returns the vertex's skin matrix, each of its bones' matrices times its weight, added; vec3 helixSkinNormal(vec3 normal)
// returns a normal moved as raylib moves one, by each bone's matrix inverted and transposed, times its weight, added, and not normalized.
//
// A shader including it skins on the GPU: a mesh UpdateModelAnimation posed is drawn with its bones written into the palette and
// boneOffset set, so one model drawn in many poses in a frame draws each as it was asked for. A mesh drawn before any UpdateModelAnimation
// posed it, or without bones, is drawn in its bind pose, as are the vertices with no weight at all.
//
//     #version 330
//     #include <helix/raylib/shaders/skinning.glsl>
//     in vec3 vertexPosition;
//     in vec3 vertexNormal;
//     uniform mat4 mvp;
//     out vec3 fragNormal;
//     void main() {
//         fragNormal = helixSkinNormal(vertexNormal);
//         gl_Position = mvp*helixSkin()*vec4(vertexPosition, 1.0);
//     }
#ifndef HELIX_RAYLIB_SHADERS_SKINNING_GLSL
#define HELIX_RAYLIB_SHADERS_SKINNING_GLSL

in vec4 vertexBoneIds;
in vec4 vertexBoneWeights;

uniform sampler2D bonePalette;
uniform int boneOffset;

// A bone's matrix: four texels of the palette, its columns, 64 bones a row, the draw's first at boneOffset - 1.
mat4 helixBoneMatrix(float id) {
    int bone = int(id + 0.5) + boneOffset - 1;
    ivec2 at = ivec2(bone % 64 * 4, bone / 64);
    return mat4(texelFetch(bonePalette, at, 0), texelFetch(bonePalette, at + ivec2(1, 0), 0), texelFetch(bonePalette, at + ivec2(2, 0), 0),
        texelFetch(bonePalette, at + ivec2(3, 0), 0));
}

mat4 helixSkin() {
    if (boneOffset == 0)
        return mat4(1.0);
    mat4 skin = mat4(0.0);
    bool weighted = false;
    for (int i = 0; i < 4; i++) {
        float weight = vertexBoneWeights[i];
        if (weight != 0.0) {
            skin += helixBoneMatrix(vertexBoneIds[i])*weight;
            weighted = true;
        }
    }
    return weighted ? skin : mat4(1.0);
}

vec3 helixSkinNormal(vec3 normal) {
    if (boneOffset == 0)
        return normal;
    vec3 moved = vec3(0.0);
    bool weighted = false;
    for (int i = 0; i < 4; i++) {
        float weight = vertexBoneWeights[i];
        if (weight != 0.0) {
            mat4 m = helixBoneMatrix(vertexBoneIds[i]);
            vec3 a = m[0].xyz, b = m[1].xyz, c = m[2].xyz;
            // The matrix inverted and transposed: its cofactors over its determinant.
            mat3 inverseTranspose = mat3(cross(b, c), cross(c, a), cross(a, b))/dot(a, cross(b, c));
            moved += inverseTranspose*normal*weight;
            weighted = true;
        }
    }
    return weighted ? moved : normal;
}

#endif
