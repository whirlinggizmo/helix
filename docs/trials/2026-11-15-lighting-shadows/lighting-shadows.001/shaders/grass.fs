#version 330

#include <helix/raylib/shaders/pbr.glsl>

in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;

uniform vec4 colDiffuse;

out vec4 finalColor;

void main()
{
    vec3 green = mix(vec3(0.05, 0.25, 0.05), vec3(0.35, 0.6, 0.15), fragTexCoord.y);
    vec4 base = vec4(green, 1.0)*colDiffuse*fragColor;
    finalColor = helixPbr(base, 0.0, 0.9, 1.0, vec3(0.0), fragPosition, normalize(fragNormal));
}
