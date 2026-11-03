#version 450
// The texture repeated four times across, darkened by the fragment stage's block 1's tint, set each frame.
layout(location = 0) in vec2 v_uv;
layout(binding = 1) uniform shade { vec4 tint; };
layout(binding = 0) uniform sampler2D checks;
layout(location = 0) out vec4 color;
void main() { color = texture(checks, v_uv * 4.0) * tint; }
