#version 330
// The lit shader's vertex stage skinned, for a mesh UpdateModelAnimation posed: <helix/raylib/shaders/vertex.glsl> on each vertex and
// its normal moved by its bones (<helix/raylib/shaders/skinning.glsl>).
#include <helix/raylib/shaders/skinning.glsl>
#include <helix/raylib/shaders/vertex.glsl>
void main() {
    helixVertex(helixSkin()*vec4(vertexPosition, 1.0), helixSkinNormal(vertexNormal));
}
