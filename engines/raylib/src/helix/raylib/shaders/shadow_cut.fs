#version 330
// helix-raylib's shadow pass fragment stage (BeginShadowMode), under a vertex stage passing fragTexCoord: depth alone, nothing written
// where the albedo's alpha, texture0's times colDiffuse's, is below the material's alphaCutoff.
in vec2 fragTexCoord;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float alphaCutoff;
void main() {
    if (texture(texture0, fragTexCoord).a*colDiffuse.a < alphaCutoff)
        discard;
}
