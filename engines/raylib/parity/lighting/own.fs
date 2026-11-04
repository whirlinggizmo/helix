#version 330
// A program's own fragment stage over <helix/raylib/shaders/lights.glsl>, lit as raylib's lighting.fs lights.
#include <helix/raylib/shaders/lights.glsl>
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
    vec4 texel = texture(texture0, fragTexCoord);
    finalColor = helixLight(texel, colDiffuse*fragColor, fragPosition, fragNormal);
}
