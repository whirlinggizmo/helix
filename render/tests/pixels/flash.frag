#version 300 es
// A program's fragment stage over the batch's: the vertex's customData as its color, and a uniform the program writes added.
precision highp float;
in vec4 customData;
uniform vec4 extra;
out vec4 fragColor;

void main() {
	fragColor = vec4(customData.rgb + extra.rgb, 1.0);
}
