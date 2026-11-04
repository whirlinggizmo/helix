#version 330
// A program's own vertex stage skinning through helix-raylib's include, drawn where scene.c draws raylib's skinning.vs.
#include <helix/raylib/shaders/skinning.glsl>
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
uniform mat4 mvp;
out vec2 fragTexCoord;
out vec4 fragColor;
void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    gl_Position = mvp*helixSkin()*vec4(vertexPosition, 1.0);
}
