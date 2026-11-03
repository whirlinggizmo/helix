#version 450
// A position in clip space and a value from -1 to 1 shown as a color from 0 to 1, for the signed normalized vertex formats. Block 0 is the
// clip scale the adapter writes (ClipScale).
layout(location = 0) in vec2 position;
layout(location = 1) in vec4 value;
layout(binding = 0) uniform clip { vec4 scale; };
layout(location = 0) out vec4 v_color;
void main() {
    gl_Position = vec4(position * scale.xy, 0.0, 1.0);
    v_color = value * 0.5 + 0.5;
}
