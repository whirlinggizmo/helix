#version 330
in vec3 vertexPosition;
in vec4 vertexTangent;
in vec2 vertexTexCoord2;
uniform mat4 mvp;
out vec4 c;
void main() { c = vec4(vertexTangent.xyz*0.5 + 0.5, 1.0) + vec4(vertexTexCoord2, 0.0, 0.0); gl_Position = mvp*vec4(vertexPosition, 1.0); }
