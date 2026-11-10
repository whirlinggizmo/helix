#version 330
in vec2 fragTexCoord;
uniform sampler2D texture0;
uniform sampler2D emissiveMap;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
	finalColor = texture(texture0, fragTexCoord) * colDiffuse + texture(emissiveMap, fragTexCoord);
}
