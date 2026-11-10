#version 330
// A program's own fragment stage lit by helix-raylib's lights.glsl, as its comment shows (ShaderFileTests).
#include <helix/raylib/shaders/lights.glsl>
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
    finalColor = helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal);
}
