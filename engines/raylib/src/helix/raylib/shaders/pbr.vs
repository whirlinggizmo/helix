#version 330
// helix-raylib's PBR shader's vertex stage (LoadPbrShader): <helix/raylib/shaders/pbr_vertex.glsl> on the mesh's own vertices.
#include <helix/raylib/shaders/pbr_vertex.glsl>
void main() {
    helixPbrVertex(vec4(vertexPosition, 1.0), vertexNormal, vertexTangent.xyz);
}
