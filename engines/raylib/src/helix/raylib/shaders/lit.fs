#version 330
// raylib's examples' lighting.fs (raylib 5.5) over <helix/raylib/shaders/lights.glsl>: helix-raylib's lit shader's fragment stage.
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
