#version 450
// A quad's corners, placed by the vertex stage's block.
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texCoord;
layout(location = 2) in vec3 unread;
layout(binding = 0) uniform Placement {
    vec4 offsetScale;
};
layout(location = 0) out vec2 uv;
void main() {
    gl_Position = vec4(position * offsetScale.zw + offsetScale.xy, 0.0, 1.0);
    uv = texCoord;
}
