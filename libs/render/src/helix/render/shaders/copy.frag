#version 300 es
// A texture copied texel for texel.
precision highp float;
in vec2 texCoord;
uniform sampler2D source;
out vec4 fragColor;

void main() {
	fragColor = texture(source, texCoord);
}
