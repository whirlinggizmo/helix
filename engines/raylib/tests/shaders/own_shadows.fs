#version 330
// A program's own fragment stage reading helix-raylib's shadows.glsl alone, as its comment shows (ShadowsTests).
#include <helix/raylib/shaders/shadows.glsl>
in vec3 fragPosition;
in vec3 fragNormal;
out vec4 finalColor;
void main() {
    float lit = helixShadow(0, fragPosition, fragNormal);
    finalColor = vec4(vec3(0.2 + 0.8*lit), 1.0);
}
