#version 300 es
// A program's material fragment stage over the mesh vertex stage: the material's base color as stored, and the vertex color.
precision highp float;
in vec4 color;
uniform vec4 baseColor;
out vec4 fragColor;

void main() {
	fragColor = baseColor * color;
}
