#version 330
// The lit shader's vertex stage instanced, for DrawMeshInstanced: <helix/raylib/shaders/vertex.glsl> on each vertex and its normal
// moved by its instance's transform (<helix/raylib/shaders/instancing.glsl>).
#include <helix/raylib/shaders/vertex.glsl>
#include <helix/raylib/shaders/instancing.glsl>
void main() {
    helixVertex(helixInstance(vec4(vertexPosition, 1.0)), helixInstanceNormal(vertexNormal));
}
