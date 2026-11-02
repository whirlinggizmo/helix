#version 300 es
// Batch2D's own vertex stage: a vertex in the batch's units placed by the view, its texture coordinates and color passed on.
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
uniform mat4 modelViewProjection;
out vec2 texCoord;
out vec4 color;

void main() {
	texCoord = vertexTexCoord;
	color = vertexColor;
	gl_Position = modelViewProjection * vec4(vertexPosition, 1.0);
}
