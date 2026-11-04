#version 330
// raylib's default fragment stage, as its rlgl writes it: helix-raylib's unlit shader.
in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
void main() {
    vec4 texelColor = texture(texture0, fragTexCoord);
    finalColor = texelColor*colDiffuse*fragColor;
}
