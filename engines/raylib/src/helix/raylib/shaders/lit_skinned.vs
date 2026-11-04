#version 330
// The lit shader's vertex stage skinned, for a mesh UpdateModelAnimation posed: lit.vs, each vertex and its normal moved by its bones
// (<helix/raylib/shaders/skinning.glsl>).
#include <helix/raylib/shaders/skinning.glsl>
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;
uniform mat4 mvp;
uniform mat4 matModel;
uniform mat4 matNormal;
out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;
void main() {
    vec4 position = helixSkin()*vec4(vertexPosition, 1.0);
    fragPosition = vec3(matModel*position);
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragNormal = normalize(vec3(matNormal*vec4(helixSkinNormal(vertexNormal), 1.0)));
    gl_Position = mvp*position;
}
