#version 450
// The texture times the vertex's color: shapes draw with a white texel.
layout(location = 0) in vec2 v_uv;
layout(location = 1) in vec4 v_tint;
layout(binding = 0) uniform sampler2D image;
layout(location = 0) out vec4 color;
void main() { color = texture(image, v_uv) * v_tint; }
