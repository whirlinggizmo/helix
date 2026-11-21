#version 330
// raylib's default vertex stage instanced, each vertex moved by its instance's transform (<helix/raylib/shaders/instancing.glsl>):
// the shadow pass's for the lit and PBR shaders drawn by DrawMeshInstanced, placing a vertex as they do.
#include <helix/raylib/shaders/instancing.glsl>
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
out vec2 fragTexCoord;
out vec4 fragColor;
uniform mat4 mvp;
void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    gl_Position = mvp*helixInstance(vec4(vertexPosition, 1.0));
}
