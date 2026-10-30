#version 450
// A position in screen pixels, a texture coordinate and a color per vertex; block 0 holds the screen's size, to reach clip space.
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 tint;
layout(binding = 0) uniform screen { vec4 size; };
layout(location = 0) out vec2 v_uv;
layout(location = 1) out vec4 v_tint;
void main() {
    gl_Position = vec4(position.x / size.x * 2.0 - 1.0, 1.0 - position.y / size.y * 2.0, 0.0, 1.0);
    v_uv = uv;
    v_tint = tint;
}
