#version 450
// A position scaled by the shared block's scale, and by block 0's clip scale, at an offset in the block (the pipeline names it).
#include "shared.glsl"
layout(location = 0) in vec2 position;
layout(binding = 0) uniform clip { vec4 other; vec4 flipped; };
void main() { gl_Position = vec4(position * scale.xy * flipped.xy, 0.0, 1.0); }
