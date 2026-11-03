#version 450
// A position in clip space and a texture coordinate per vertex, block 0 the clip scale as in color.vert.
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 uv;
layout(binding = 0) uniform clip { vec4 scale; };
layout(location = 0) out vec2 v_uv;
void main() {
    gl_Position = vec4(position * scale.xy, 0.0, 1.0);
    v_uv = uv;
}
