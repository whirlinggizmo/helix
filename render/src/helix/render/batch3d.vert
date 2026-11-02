#version 300 es
// Batch3D's own vertex stage for its batch draws but wide lines and large points: a vertex placed by the view, its texture coordinates
// and color passed on, and its position, which the clip planes cut by.
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
uniform mat4 modelViewProjection;
out vec2 texCoord;
out vec4 color;
out vec3 worldPosition;

void main() {
	texCoord = vertexTexCoord;
	color = vertexColor;
	worldPosition = vertexPosition;
	gl_Position = modelViewProjection * vec4(vertexPosition, 1.0);
}
