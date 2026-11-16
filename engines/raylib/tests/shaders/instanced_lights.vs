#version 330
// A program's own vertex stage for DrawMeshInstanced under own_lights.fs (LightingTests): each instance placed by its transform.
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;
in mat4 instanceTransform;
uniform mat4 mvp;
out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;
void main() {
    fragPosition = vec3(instanceTransform*vec4(vertexPosition, 1.0));
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragNormal = normalize(mat3(instanceTransform)*vertexNormal);
    gl_Position = mvp*vec4(fragPosition, 1.0);
}
