#version 330
// helix-raylib's particle fragment stage (the Particles extra's 3D emitters): the texture tinted by the particle's color.
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
uniform sampler2D texture0;
out vec4 finalColor;
void main() {
    finalColor = texture(texture0, fragTexCoord)*fragColor;
}
