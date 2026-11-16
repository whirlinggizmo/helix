#version 330
// raylib's examples' lighting.fs (raylib 5.5) over <helix/raylib/shaders/lights.glsl>: helix-raylib's lit shader's fragment stage, and
// unlitValue, 1 for a material marked unlit, drawn in its color and the light it gives off.
#include <helix/raylib/shaders/lights.glsl>
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float unlitValue;
out vec4 finalColor;
void main() {
    vec4 texelColor = texture(texture0, fragTexCoord);
    vec4 tint = colDiffuse*fragColor;
    if (unlitValue > 0.5) {
        if (texelColor.a*tint.a < alphaCutoff)
            discard;
        finalColor = texelColor*tint;
        finalColor.rgb += emissiveColor + modelEmissiveColor;
        return;
    }
    finalColor = helixLight(texelColor, tint, fragPosition, fragNormal);
}
