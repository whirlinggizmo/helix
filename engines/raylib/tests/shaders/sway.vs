#version 330
// A program's own vertex stage swaying its vertices by a uniform (ShadowsTests): the shadow pass draws through its shadow variant, given
// the uniform as the draw is.
#include <helix/raylib/shaders/vertex.glsl>
uniform float sway;
void main() {
    helixVertex(vec4(vertexPosition + vec3(sway*vertexPosition.y, 0.0, 0.0), 1.0), vertexNormal);
}
