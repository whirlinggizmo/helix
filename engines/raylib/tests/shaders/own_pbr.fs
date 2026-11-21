#version 330
// A program's own fragment stage lit by helix-raylib's pbr.glsl, as its comment shows (PbrTests).
#include <helix/raylib/shaders/pbr.glsl>
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
    vec4 texel = texture(texture0, fragTexCoord);
    vec4 base = vec4(helixDecodeSrgb(texel.rgb), texel.a)*colDiffuse*fragColor;
    finalColor = helixPbr(base, metallicValue, roughnessValue, 1.0, emissiveColor, fragPosition, fragNormal);
}
