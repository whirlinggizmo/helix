#version 450
// A position and a texture coordinate per vertex; block 0, set each frame, moves every vertex.
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 uv;
layout(binding = 0) uniform place { vec4 offset; };
layout(location = 0) out vec2 v_uv;
void main() {
    gl_Position = vec4(position + offset.xy, 0.0, 1.0);
    v_uv = uv;
}
