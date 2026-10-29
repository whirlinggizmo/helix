#version 450
layout(location = 0) in vec2 v_uv;
layout(binding = 0) uniform sampler2D image;
layout(location = 0) out vec4 result;
void main() { result = texture(image, v_uv); }
