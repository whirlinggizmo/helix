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
    vec3 base = mix(vec3(0.10, 0.28, 0.06), vec3(0.45, 0.65, 0.15), fragTexCoord.y);
    vec3 n = normalize(fragNormal);
    if (!gl_FrontFacing) n = -n;
    finalColor = helixPbr(vec4(base, 1.0)*colDiffuse, 0.0, 0.9, 1.0, vec3(0.0), fragPosition, n);
}
