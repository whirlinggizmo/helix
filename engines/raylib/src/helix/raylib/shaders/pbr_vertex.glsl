// <helix/raylib/shaders/pbr_vertex.glsl>: the PBR shader's vertex stage (LoadPbrShader), for pbr.vs and pbr_skinned.vs.
//
// It is vertex.glsl with the tangent: the attribute vertexTangent, the output fragTangent pbr.fs reads, and
// void helixPbrVertex(vec4 position, vec3 normal, vec3 tangent), helixVertex and the tangent sent on, from a vertex's position, normal
// and tangent in the mesh's own space: as the mesh has them, or moved by its bones.
#ifndef HELIX_RAYLIB_SHADERS_PBR_VERTEX_GLSL
#define HELIX_RAYLIB_SHADERS_PBR_VERTEX_GLSL
#include <helix/raylib/shaders/vertex.glsl>

in vec4 vertexTangent;
out vec4 fragTangent;

void helixPbrVertex(vec4 position, vec3 normal, vec3 tangent) {
    helixVertex(position, normal);
    // A mesh without tangents sends zero, which pbr.fs reads as no tangent frame, rather than the NaN normalize(0) makes.
    vec3 moved = mat3(matModel)*tangent;
    fragTangent = vec4(dot(moved, moved) > 0.0 ? normalize(moved) : vec3(0.0), vertexTangent.w);
}

#endif
