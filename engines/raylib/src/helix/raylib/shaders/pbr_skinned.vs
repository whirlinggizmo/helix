#version 330
// The PBR shader's vertex stage skinned, for a mesh UpdateModelAnimation posed: <helix/raylib/shaders/pbr_vertex.glsl> on each vertex,
// its normal and its tangent moved by its bones (<helix/raylib/shaders/skinning.glsl>).
#include <helix/raylib/shaders/skinning.glsl>
#include <helix/raylib/shaders/pbr_vertex.glsl>
void main() {
    mat4 skin = helixSkin();
    helixPbrVertex(skin*vec4(vertexPosition, 1.0), helixSkinNormal(vertexNormal), mat3(skin)*vertexTangent.xyz);
}
