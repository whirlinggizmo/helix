#version 450
// Block 2's color, from the fragment stage.
layout(binding = 2) uniform tint { vec4 color; };
layout(location = 0) out vec4 result;
void main() { result = color; }
