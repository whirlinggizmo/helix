#version 330
// The lit shader's vertex stage instanced and skinned, for a mesh UpdateModelAnimation posed drawn by DrawMeshInstanced:
// <helix/raylib/shaders/vertex.glsl> on each vertex and its normal moved by its bones (<helix/raylib/shaders/skinning.glsl>), then by
// its instance's transform (<helix/raylib/shaders/instancing.glsl>).
#include <helix/raylib/shaders/skinning.glsl>
#include <helix/raylib/shaders/vertex.glsl>
#include <helix/raylib/shaders/instancing.glsl>
void main() {
    helixVertex(helixInstance(helixSkin()*vec4(vertexPosition, 1.0)), helixInstanceNormal(helixSkinNormal(vertexNormal)));
}
