#version 330
// helix-raylib's lit shader's vertex stage (LoadLightingShader): <helix/raylib/shaders/vertex.glsl> on the mesh's own vertices.
#include <helix/raylib/shaders/vertex.glsl>
void main() {
    helixVertex(vec4(vertexPosition, 1.0), vertexNormal);
}
