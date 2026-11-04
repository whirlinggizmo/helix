#version 330
// raylib's default vertex stage skinned, for a mesh UpdateModelAnimation posed: the unlit one, each vertex moved by its skin
// matrix (<helix/raylib/shaders/skinning.glsl>).
#include <helix/raylib/shaders/skinning.glsl>
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
out vec2 fragTexCoord;
out vec4 fragColor;
uniform mat4 mvp;
void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    gl_Position = mvp*helixSkin()*vec4(vertexPosition, 1.0);
}
