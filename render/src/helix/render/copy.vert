#version 300 es
// A texture copied whole: one triangle over the target, its corners (0, 0), (2, 0) and (0, 2).
precision highp float;
in vec2 corner;
out vec2 texCoord;

void main() {
	texCoord = vec2(corner.x, 1.0 - corner.y);
	gl_Position = vec4(corner * 2.0 - 1.0, 0.0, 1.0);
}
