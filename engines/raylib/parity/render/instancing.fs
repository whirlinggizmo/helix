#version 330
in vec3 n;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() { finalColor = vec4(n*0.5 + 0.5, 1.0)*colDiffuse; }
