#version 450
// A position and seven numbers, each from a buffer of its own, the most a pipeline reads (PipelineDesc), summed into a color. Block 0 is
// the clip scale the adapter writes (ClipScale).
layout(location = 0) in vec2 position;
layout(location = 1) in float a1;
layout(location = 2) in float a2;
layout(location = 3) in float a3;
layout(location = 4) in float a4;
layout(location = 5) in float a5;
layout(location = 6) in float a6;
layout(location = 7) in float a7;
layout(binding = 0) uniform clip { vec4 scale; };
layout(location = 0) out vec4 v_color;
void main() {
    gl_Position = vec4(position * scale.xy, 0.0, 1.0);
    v_color = vec4(a1 + a2, a3 + a4, a5 + a6, a7);
}
