#version 330
// The PBR shader's vertex stage instanced and skinned, for a mesh UpdateModelAnimation posed drawn by DrawMeshInstanced:
// <helix/raylib/shaders/pbr_vertex.glsl> on each vertex, its normal and its tangent moved by its bones
// (<helix/raylib/shaders/skinning.glsl>), then by its instance's transform (<helix/raylib/shaders/instancing.glsl>).
#include <helix/raylib/shaders/skinning.glsl>
#include <helix/raylib/shaders/pbr_vertex.glsl>
#include <helix/raylib/shaders/instancing.glsl>
void main() {
    mat4 skin = helixSkin();
    helixPbrVertex(helixInstance(skin*vec4(vertexPosition, 1.0)), helixInstanceNormal(helixSkinNormal(vertexNormal)),
        mat3(instanceTransform)*mat3(skin)*vertexTangent.xyz);
}
