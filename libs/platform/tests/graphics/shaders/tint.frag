#version 450
// The fragment stage's block 2's color (a draw's uniforms at 4 + 2: blocks are numbered by stage).
layout(binding = 2) uniform tint { vec4 color; };
layout(location = 0) out vec4 result;
void main() { result = color; }
