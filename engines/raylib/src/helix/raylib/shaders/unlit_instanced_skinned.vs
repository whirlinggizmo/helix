#version 330
// raylib's default vertex stage instanced and skinned, each vertex moved by its skin matrix (<helix/raylib/shaders/skinning.glsl>),
// then by its instance's transform (<helix/raylib/shaders/instancing.glsl>): the shadow pass's for the lit and PBR shaders' posed
// meshes drawn by DrawMeshInstanced.
#include <helix/raylib/shaders/skinning.glsl>
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
    gl_Position = mvp*helixInstance(helixSkin()*vec4(vertexPosition, 1.0));
}
