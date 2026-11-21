#version 330
// The PBR shader's vertex stage instanced, for DrawMeshInstanced: <helix/raylib/shaders/pbr_vertex.glsl> on each vertex, its normal
// and its tangent moved by its instance's transform (<helix/raylib/shaders/instancing.glsl>).
#include <helix/raylib/shaders/pbr_vertex.glsl>
#include <helix/raylib/shaders/instancing.glsl>
void main() {
    helixPbrVertex(helixInstance(vec4(vertexPosition, 1.0)), helixInstanceNormal(vertexNormal), mat3(instanceTransform)*vertexTangent.xyz);
}
