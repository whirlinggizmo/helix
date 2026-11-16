#version 330
// helix-raylib's lit particle fragment stage (an Emitter3D's lit): the texture tinted by the particle's color, lit by the scene's lights
// at the particle's place (<helix/raylib/shaders/lights.glsl>), from every way, its shadows taken from them, and the emitter's ambient
// (lights.glsl's ambient) from all around, as helixLight returns a color: gamma corrected.
#include <helix/raylib/shaders/lights.glsl>
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
uniform sampler2D texture0;
out vec4 finalColor;
void main() {
    vec4 color = texture(texture0, fragTexCoord)*fragColor;
    vec3 light = ambient.rgb;
    for (int i = 0; i < MAX_LIGHTS; i++)
        if (lights[i].enabled == 1)
            light += lights[i].color.rgb*helixLightStrength(i, fragPosition)*helixShadow(i, fragPosition, helixLightDirection(i, fragPosition));
    finalColor = vec4(pow(color.rgb*light, vec3(1.0/2.2)), color.a);
}
