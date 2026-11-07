#version 330
in vec3 fragPosition;
uniform samplerCube cubeMap;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
    finalColor = texture(cubeMap, fragPosition)*colDiffuse;
}
