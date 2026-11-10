#version 330
// A program's own vertex stage for own_lights.fs (ShaderFileTests): <helix/raylib/shaders/vertex.glsl> on the mesh's own vertices.
#include <helix/raylib/shaders/vertex.glsl>
void main() {
    helixVertex(vec4(vertexPosition, 1.0), vertexNormal);
}
