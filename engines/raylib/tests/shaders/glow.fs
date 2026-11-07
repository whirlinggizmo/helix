#version 330
in vec2 fragTexCoord;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float glow = 0.5;
out vec4 finalColor;
void main() {
	finalColor = texture(texture0, fragTexCoord) * colDiffuse * (1.0 + glow);
}
