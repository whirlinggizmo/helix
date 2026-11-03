#version 450
// A position moved by block 1's offset, at its depth (z), block 0 the clip scale as in color.vert.
layout(location = 0) in vec2 position;
layout(binding = 0) uniform clip { vec4 scale; };
layout(binding = 1) uniform move { vec4 offset; };
void main() { gl_Position = vec4((position + offset.xy) * scale.xy, offset.z, 1.0); }
